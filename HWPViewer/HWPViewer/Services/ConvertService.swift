//
//  ConvertService.swift
//  HWPViewer
//
//  PDF / DOCX → HWP via HwpEditorKit 1.2 (`RhwpDocument.importPDF` / `importDOCX` + `exportHWP`).
//  Runs the Rust importer off the main thread; the output lands in Documents and the file store is notified.
//

import Foundation
import HwpEditorKit
import SPNComponent

enum ConvertError: LocalizedError {
    /// Word 97-2003 binary `.doc` (OLE) — the engine only reads DOCX (zip + XML).
    case unsupportedLegacyDoc
    case unsupportedKind
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedLegacyDoc: return L10n.convertErrorLegacyDoc
        case .unsupportedKind: return L10n.convertFailed
        case .cancelled: return nil
        case .failed(let message): return message
        }
    }
}

struct ConvertResult {
    let outputURL: URL
    let size: Int64
}

final class ConvertService {
    static let shared = ConvertService()

    /// Converts `source` to an HWP named `outputName` in Documents. `progress` is 0…1 on the main thread.
    /// Progress is coarse (read → import → export → write): the engine reports no intermediate steps.
    func convert(source: FileItem, outputName: String, progress: @escaping (Double) -> Void) async throws -> ConvertResult {
        let kind = source.kind
        let url = source.url
        await MainActor.run { progress(0.1) }

        let hwp: Data = try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            try Task.checkCancellation()
            let document: RhwpDocument
            switch kind {
            case .pdf:
                document = try RhwpDocument.importPDF(data)
            case .doc, .docx:
                if data.isLegacyDoc { throw ConvertError.unsupportedLegacyDoc }
                document = try RhwpDocument.importDOCX(data)
            case .hwp, .hwpx:
                throw ConvertError.unsupportedKind
            }
            try Task.checkCancellation()
            return try document.exportHWP()
        }.value

        await MainActor.run { progress(0.85) }
        try Task.checkCancellation()
        let destination = FileStore.shared.uniqueURL(for: "\(outputName).hwp")
        try hwp.write(to: destination, options: .atomic)
        FileStore.shared.notifyChanged()
        await MainActor.run { progress(1.0) }
        logger("[Convert] \(source.displayName) → \(destination.lastPathComponent) (\(hwp.count) bytes)")
        return ConvertResult(outputURL: destination, size: Int64(hwp.count))
    }
}
