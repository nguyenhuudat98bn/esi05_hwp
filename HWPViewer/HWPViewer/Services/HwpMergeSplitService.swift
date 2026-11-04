//
//  HwpMergeSplitService.swift
//  HWPViewer
//
//  Merge several HWP/HWPX files into one HWP, or extract picked pages of one file into a new file,
//  with the HwpEditorKit engine (`RhwpDocument.append` / `extractPages`, kit branch `poc/merge-split`).
//  Engine work runs off the main thread; outputs land in Documents and the file store is notified.
//
//  Extract keeps whole paragraphs: a paragraph that runs across a page edge comes along whole, so the
//  output can be a page longer than the pages picked (the engine reports the real page count).
//

import Foundation
import HwpEditorKit
import SPNComponent

/// A file written by merge / split.
struct DocumentOutput {
    let url: URL
    let size: Int64
    let pageCount: Int

    var name: String { url.lastPathComponent }
}

enum MergeSplitError: LocalizedError {
    case needTwoFiles
    case noPages

    var errorDescription: String? {
        switch self {
        case .needTwoFiles: return L10n.mergeNeedTwoFiles
        case .noPages: return L10n.convertFailed
        }
    }
}

final class HwpMergeSplitService {
    static let shared = HwpMergeSplitService()

    private init() {}

    /// Appends `files` in order into one HWP named `outputName` (HWPX inputs are converted by the engine).
    func merge(_ files: [FileItem], outputName: String) async throws -> DocumentOutput {
        guard files.count >= 2 else { throw MergeSplitError.needTwoFiles }
        try await HwpEngine.prepare()
        let result: (data: Data, pages: Int) = try await Task.detached(priority: .userInitiated) {
            let merged = try RhwpDocument(contentsOf: files[0].url)
            for file in files.dropFirst() {
                try Task.checkCancellation()
                _ = try merged.append(try RhwpDocument(contentsOf: file.url))
            }
            try Task.checkCancellation()
            return (try merged.exportHWP(), merged.pageCount)
        }.value
        let output = try save(result.data, named: "\(outputName).hwp", pages: result.pages)
        logger("[Merge] \(files.count) files → \(output.name) (\(result.pages) pages, \(output.size) bytes)")
        return output
    }

    /// Picked pages (1-based) of `file` → one new file named `outputName`, in the source's format.
    func extract(_ file: FileItem, pages: [Int], outputName: String) async throws -> DocumentOutput {
        let pages = Array(Set(pages)).sorted()
        guard let first = pages.first, first >= 1 else { throw MergeSplitError.noPages }
        try await HwpEngine.prepare()
        let url = file.url
        let asHWPX = file.kind == .hwpx
        let result: (data: Data, pages: Int) = try await Task.detached(priority: .userInitiated) {
            let document = try RhwpDocument(contentsOf: url)
            let report = try document.extractPages(pages)
            return (asHWPX ? try document.exportHWPX() : try document.exportHWP(), report.pagesAfter)
        }.value
        let output = try save(result.data, named: "\(outputName).\(file.kind.rawValue)", pages: result.pages)
        logger("[Split] \(file.name): \(pages.count) pages → \(output.name) (\(result.pages) pages)")
        return output
    }

    private func save(_ data: Data, named fileName: String, pages: Int) throws -> DocumentOutput {
        let destination = FileStore.shared.uniqueURL(for: fileName)
        try data.write(to: destination, options: .atomic)
        FileStore.shared.notifyChanged()
        return DocumentOutput(url: destination, size: Int64(data.count), pageCount: pages)
    }
}
