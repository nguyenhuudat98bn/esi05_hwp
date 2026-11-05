//
//  HwpFileInspector.swift
//  HWPViewer
//
//  Opens a file with the engine before a tool commits to it: Merge refuses files the engine cannot
//  read (ESI05-61), Split also refuses single-page files (ESI05-60) and says so on the spot instead
//  of moving on to a screen that fails (ESI05-64). Results are cached per file and modification date,
//  so ticking / unticking the same file does not reopen it.
//

import Foundation
import HwpEditorKit

enum HwpFileCheck: Equatable {
    case readable(pages: Int)
    case unreadable
}

@MainActor
final class HwpFileInspector {
    static let shared = HwpFileInspector()

    private var cache: [String: HwpFileCheck] = [:]

    private init() {}

    /// Throws only when the engine cannot start (fonts not downloaded and the device is offline).
    func inspect(_ item: FileItem) async throws -> HwpFileCheck {
        let key = "\(item.url.path)|\(item.modifiedAt.timeIntervalSince1970)|\(item.size)"
        if let cached = cache[key] { return cached }
        try await HwpEngine.prepare()
        let url = item.url
        let check: HwpFileCheck = await Task.detached(priority: .userInitiated) {
            guard let document = try? RhwpDocument(contentsOf: url), document.pageCount > 0 else { return .unreadable }
            return .readable(pages: document.pageCount)
        }.value
        cache[key] = check
        return check
    }
}
