//
//  FileStore.swift
//  HWPViewer
//
//  Scans the app Documents folder and keeps a small JSON index (recent / bookmark) in UserDefaults.
//  Keys are file names (relative to Documents) so the index survives container path changes.
//

import Foundation
import Combine
import SPNComponent

enum FileStoreError: LocalizedError {
    case nameExists
    case invalidName
    case unsupported
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .nameExists: return L10n.renameErrorExists
        case .invalidName: return L10n.renameErrorInvalid
        case .unsupported: return L10n.importUnsupported
        case .copyFailed: return L10n.importFailed
        }
    }
}

final class FileStore {
    static let shared = FileStore()

    /// Emits whenever the file list or the index changes.
    let didChange = PassthroughSubject<Void, Never>()

    private struct Meta: Codable {
        var lastOpened: Date?
        var bookmarked: Bool
        /// Trang (0-based) đang xem khi rời viewer — mở lại cuộn về đúng trang (ni03).
        var lastPage: Int?
    }

    private let defaults = UserDefaults.standard
    private let indexKey = "HWP_FILE_INDEX_V1"
    private var index: [String: Meta] {
        didSet { persistIndex() }
    }

    let documentsURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private init() {
        if let data = defaults.data(forKey: indexKey),
           let decoded = try? JSONDecoder().decode([String: Meta].self, from: data) {
            index = decoded
        } else {
            index = [:]
        }
    }

    private func persistIndex() {
        if let data = try? JSONEncoder().encode(index) {
            defaults.set(data, forKey: indexKey)
        }
    }

    // MARK: - Query

    /// All supported files in Documents, newest first.
    func allFiles(extensions: Set<String>? = nil) -> [FileItem] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
        guard let urls = try? fm.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else {
            return []
        }
        var items: [FileItem] = []
        for url in urls {
            guard let kind = FileKind(url: url) else { continue }
            if let extensions, !extensions.contains(kind.rawValue) { continue }
            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isRegularFile ?? true else { continue }
            let meta = index[url.lastPathComponent]
            items.append(FileItem(
                url: url,
                name: url.lastPathComponent,
                kind: kind,
                size: Int64(values?.fileSize ?? 0),
                modifiedAt: values?.contentModificationDate ?? .distantPast,
                lastOpenedAt: meta?.lastOpened,
                isBookmarked: meta?.bookmarked ?? false
            ))
        }
        return items.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func hwpFiles() -> [FileItem] { allFiles(extensions: FileKind.hwpExtensions) }

    func files(for family: FileFamily) -> [FileItem] { allFiles(extensions: family.extensions) }

    func recentFiles() -> [FileItem] {
        hwpFiles()
            .filter { $0.lastOpenedAt != nil }
            .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
    }

    func bookmarkedFiles() -> [FileItem] {
        hwpFiles().filter { $0.isBookmarked }
    }

    func item(at url: URL) -> FileItem? {
        allFiles().first { $0.url.lastPathComponent == url.lastPathComponent }
    }

    func fileExists(named name: String) -> Bool {
        FileManager.default.fileExists(atPath: documentsURL.appendingPathComponent(name).path)
    }

    // MARK: - Index mutations

    func markOpened(_ url: URL) {
        var meta = index[url.lastPathComponent] ?? Meta(lastOpened: nil, bookmarked: false)
        meta.lastOpened = Date()
        index[url.lastPathComponent] = meta
        didChange.send()
    }

    @discardableResult
    func toggleBookmark(_ url: URL) -> Bool {
        var meta = index[url.lastPathComponent] ?? Meta(lastOpened: nil, bookmarked: false)
        meta.bookmarked.toggle()
        index[url.lastPathComponent] = meta
        didChange.send()
        return meta.bookmarked
    }

    func isBookmarked(_ url: URL) -> Bool {
        index[url.lastPathComponent]?.bookmarked ?? false
    }

    // MARK: - Reading position

    /// 0-based page the user was on when they last left this file (nil = never saved / page 0).
    func lastPage(for url: URL) -> Int? {
        index[url.lastPathComponent]?.lastPage
    }

    /// Persists the reading position. Does not emit `didChange` (lists don't show it).
    func setLastPage(_ page: Int, for url: URL) {
        var meta = index[url.lastPathComponent] ?? Meta(lastOpened: nil, bookmarked: false)
        guard meta.lastPage != page else { return }
        meta.lastPage = page
        index[url.lastPathComponent] = meta
    }

    // MARK: - File mutations

    /// Copies a picked file into Documents (unique name) and returns the new URL.
    func importFile(from source: URL, allowed: Set<String>? = nil) throws -> URL {
        guard let kind = FileKind(url: source) else { throw FileStoreError.unsupported }
        if let allowed, !allowed.contains(kind.rawValue) { throw FileStoreError.unsupported }
        let destination = uniqueURL(for: source.lastPathComponent)
        let accessing = source.startAccessingSecurityScopedResource()
        defer { if accessing { source.stopAccessingSecurityScopedResource() } }
        do {
            var coordinatorError: NSError?
            var copyError: Error?
            NSFileCoordinator().coordinate(readingItemAt: source, options: [], error: &coordinatorError) { readURL in
                do {
                    try FileManager.default.copyItem(at: readURL, to: destination)
                } catch {
                    copyError = error
                }
            }
            if let coordinatorError { throw coordinatorError }
            if let copyError { throw copyError }
        } catch {
            logger("[FileStore] import failed: \(error)")
            throw FileStoreError.copyFailed
        }
        didChange.send()
        return destination
    }

    /// Returns a URL in Documents that does not collide: "name.hwp", "name (1).hwp", …
    func uniqueURL(for fileName: String) -> URL {
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var candidate = documentsURL.appendingPathComponent(fileName)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            candidate = documentsURL.appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }

    static let invalidNameCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")

    /// Validates a display name (without extension). Returns nil when valid.
    func validateRename(_ item: FileItem, to newDisplayName: String) -> FileStoreError? {
        let trimmed = newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .invalidName }
        if trimmed.rangeOfCharacter(from: Self.invalidNameCharacters) != nil || trimmed.hasPrefix(".") { return .invalidName }
        let newName = "\(trimmed).\(item.kind.rawValue)"
        if newName == item.name { return nil }
        if fileExists(named: newName) { return .nameExists }
        return nil
    }

    /// Renames keeping the extension; moves the index entry along.
    @discardableResult
    func rename(_ item: FileItem, to newDisplayName: String) throws -> URL {
        if let error = validateRename(item, to: newDisplayName) { throw error }
        let trimmed = newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = "\(trimmed).\(item.kind.rawValue)"
        guard newName != item.name else { return item.url }
        let destination = documentsURL.appendingPathComponent(newName)
        try FileManager.default.moveItem(at: item.url, to: destination)
        if let meta = index.removeValue(forKey: item.name) {
            index[newName] = meta
        }
        didChange.send()
        return destination
    }

    func delete(_ item: FileItem) throws {
        try FileManager.default.removeItem(at: item.url)
        index.removeValue(forKey: item.name)
        didChange.send()
    }

    /// Notifies listeners after an external change (save from editor, convert output, …).
    func notifyChanged() {
        didChange.send()
    }
}
