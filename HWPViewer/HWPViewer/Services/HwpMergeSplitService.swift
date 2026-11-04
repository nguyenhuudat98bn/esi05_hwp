//
//  HwpMergeSplitService.swift
//  HWPViewer
//
//  Merge several HWP/HWPX files into one, or split one into parts, with the HwpEditorKit engine
//  (`RhwpDocument.append` / `extractPages`, kit branch `poc/merge-split`). Engine work runs off the
//  main thread; outputs land in Documents and the file store is notified.
//
//  Split keeps whole paragraphs: a paragraph that runs across a cut goes into both parts, so a part
//  can come out a page longer or shorter than asked (the engine reports the real page count).
//

import Foundation
import HwpEditorKit
import SPNComponent

/// A file written by merge / split.
struct DocumentOutput {
    let url: URL
    let size: Int64
    let pageCount: Int
    /// Source pages it was cut from, e.g. "1–4" (split / extract only).
    let sourcePages: String?

    var name: String { url.lastPathComponent }
}

enum MergeSplitError: LocalizedError {
    case needTwoFiles
    case invalidPages

    var errorDescription: String? {
        switch self {
        case .needTwoFiles: return L10n.mergeSelectHint
        case .invalidPages: return L10n.splitInvalidRange
        }
    }
}

final class HwpMergeSplitService {
    static let shared = HwpMergeSplitService()

    private init() {}

    // MARK: - Merge

    /// Appends `files` in order into one document named `outputName`. `progress(fraction, file)` is
    /// called on the main thread before each file is added.
    func merge(_ files: [FileItem], outputName: String, asHWPX: Bool,
               progress: @escaping (Double, FileItem) -> Void) async throws -> DocumentOutput {
        guard files.count >= 2 else { throw MergeSplitError.needTwoFiles }
        try await HwpEngine.prepare()
        let result: (data: Data, pages: Int) = try await Task.detached(priority: .userInitiated) {
            let merged = try RhwpDocument(contentsOf: files[0].url)
            for index in files.indices.dropFirst() {
                try Task.checkCancellation()
                let fraction = Double(index) / Double(files.count + 1)
                await MainActor.run { progress(fraction, files[index]) }
                let next = try RhwpDocument(contentsOf: files[index].url)
                _ = try merged.append(next)
            }
            try Task.checkCancellation()
            let data = asHWPX ? try merged.exportHWPX() : try merged.exportHWP()
            return (data, merged.pageCount)
        }.value
        let output = try save(result.data, named: "\(outputName).\(asHWPX ? "hwpx" : "hwp")", pages: result.pages, sourcePages: nil)
        logger("[Merge] \(files.count) files → \(output.name) (\(result.pages) pages, \(output.size) bytes)")
        return output
    }

    // MARK: - Split

    /// One output per range (1-based, inclusive), named `<source>_part<n>`.
    func split(_ file: FileItem, ranges: [ClosedRange<Int>],
               progress: @escaping (Int, Int) -> Void) async throws -> [DocumentOutput] {
        guard !ranges.isEmpty, ranges.allSatisfy({ $0.lowerBound >= 1 }) else { throw MergeSplitError.invalidPages }
        try await HwpEngine.prepare()
        var outputs: [DocumentOutput] = []
        for (index, range) in ranges.enumerated() {
            try Task.checkCancellation()
            await MainActor.run { progress(index + 1, ranges.count) }
            let part = try await cut(file) { try $0.extractPages(from: range.lowerBound, to: range.upperBound) }
            outputs.append(try save(part.data, named: "\(file.displayName)_part\(index + 1).\(file.kind.rawValue)",
                                    pages: part.pages, sourcePages: Self.label(range)))
        }
        logger("[Split] \(file.name) → \(outputs.count) parts")
        return outputs
    }

    /// Picked pages (1-based): one file holding all of them, or one file per page.
    func extract(_ file: FileItem, pages: [Int], onePerPage: Bool,
                 progress: @escaping (Int, Int) -> Void) async throws -> [DocumentOutput] {
        let pages = Array(Set(pages)).sorted()
        guard !pages.isEmpty, pages.first! >= 1 else { throw MergeSplitError.invalidPages }
        if onePerPage {
            return try await split(file, ranges: pages.map { $0...$0 }, progress: progress)
        }
        try await HwpEngine.prepare()
        await MainActor.run { progress(1, 1) }
        let part = try await cut(file) { try $0.extractPages(pages) }
        let label = pages.map(String.init).joined(separator: ", ")
        return [try save(part.data, named: "\(file.displayName)_pages.\(file.kind.rawValue)", pages: part.pages, sourcePages: label)]
    }

    // MARK: - Helpers

    /// Loads a fresh copy of `file`, lets `extract` cut it, and exports it in the source's format.
    private func cut(_ file: FileItem, _ extract: @escaping (RhwpDocument) throws -> RhwpPageExtractReport) async throws -> (data: Data, pages: Int) {
        let url = file.url
        let asHWPX = file.kind == .hwpx
        return try await Task.detached(priority: .userInitiated) {
            let document = try RhwpDocument(contentsOf: url)
            let report = try extract(document)
            let data = asHWPX ? try document.exportHWPX() : try document.exportHWP()
            return (data, report.pagesAfter)
        }.value
    }

    private func save(_ data: Data, named fileName: String, pages: Int, sourcePages: String?) throws -> DocumentOutput {
        let destination = FileStore.shared.uniqueURL(for: fileName)
        try data.write(to: destination, options: .atomic)
        FileStore.shared.notifyChanged()
        return DocumentOutput(url: destination, size: Int64(data.count), pageCount: pages, sourcePages: sourcePages)
    }

    static func label(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }
}
