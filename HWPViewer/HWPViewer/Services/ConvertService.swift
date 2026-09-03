//
//  ConvertService.swift
//  HWPViewer
//
//  PDF / DOC → HWP. ENGINE+: HwpEditorKit 1.1.0 does not expose `rhwp_doc_import_pdf/docx`;
//  the real implementation lands with HwpEditorKit 1.2 (`RhwpDocument.importPDF(data:)`, `importDOCX(data:)`).
//  Until then the service reports `.notAvailable` so the UI flow (G3 → G4 → G5) can be exercised.
//

import Foundation

enum ConvertError: LocalizedError {
    case notAvailable
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return L10n.convertComingSoon
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

    /// True once the engine ships the import API. Toggle here when HwpEditorKit 1.2 is integrated.
    static let isAvailable = false

    /// Converts `source` to an HWP named `outputName` in Documents. `progress` is 0…1 on the main thread.
    func convert(source: FileItem, outputName: String, progress: @escaping (Double) -> Void) async throws -> ConvertResult {
        guard Self.isAvailable else {
            // Simulated progress so the loading screen can be reviewed.
            for step in 1...4 {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: 250_000_000)
                await MainActor.run { progress(Double(step) / 5.0) }
            }
            throw ConvertError.notAvailable
        }
        // TODO(HwpEditorKit 1.2):
        // let data = try Data(contentsOf: source.url)
        // let doc = source.kind == .pdf ? try RhwpDocument.importPDF(data: data) : try RhwpDocument.importDOCX(data: data)
        // let hwp = try doc.exportHWP()
        // let url = FileStore.shared.uniqueURL(for: "\(outputName).hwp"); try hwp.write(to: url)
        // FileStore.shared.notifyChanged(); return ConvertResult(outputURL: url, size: Int64(hwp.count))
        throw ConvertError.notAvailable
    }
}
