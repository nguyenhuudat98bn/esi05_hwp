//
//  FileListViewModel.swift
//  HWPViewer
//
//  Drives Home tabs (My File / Recent / Bookmark), Search and Tools → Select File.
//

import Foundation
import Combine

final class FileListViewModel {
    enum Filter: Equatable {
        case all
        case recent
        case bookmark
        case family(FileFamily)

        var extensions: Set<String>? {
            switch self {
            case .all, .recent, .bookmark: return FileKind.hwpExtensions
            case .family(let family): return family.extensions
            }
        }
    }

    @Published private(set) var items: [FileItem] = []
    @Published var filter: Filter
    @Published var query: String = ""
    /// Search screen: return no rows until the user types.
    var requiresQuery = false

    private let store: FileStore
    private var cancellables = Set<AnyCancellable>()

    init(filter: Filter = .all, store: FileStore = .shared) {
        self.filter = filter
        self.store = store

        let changes = store.didChange.map { _ in () }.prepend(())
        Publishers.CombineLatest3(
            changes,
            $filter.removeDuplicates(),
            $query.debounce(for: .milliseconds(300), scheduler: RunLoop.main).removeDuplicates()
        )
        .map { [weak self] _, filter, query -> [FileItem] in
            self?.load(filter: filter, query: query) ?? []
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.items = $0 }
        .store(in: &cancellables)
    }

    func reload() {
        items = load(filter: filter, query: query)
    }

    private func load(filter: Filter, query: String) -> [FileItem] {
        var result: [FileItem]
        switch filter {
        case .all: result = store.hwpFiles()
        case .recent: result = store.recentFiles()
        case .bookmark: result = store.bookmarkedFiles()
        case .family(let family): result = store.files(for: family)
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if requiresQuery && trimmed.isEmpty { return [] }
        if !trimmed.isEmpty {
            result = result.filter { $0.displayName.localizedCaseInsensitiveContains(trimmed) }
        }
        return result
    }

    // MARK: - Actions

    func toggleBookmark(_ item: FileItem) -> Bool {
        store.toggleBookmark(item.url)
    }

    func markOpened(_ item: FileItem) {
        store.markOpened(item.url)
    }

    func delete(_ item: FileItem) throws {
        try store.delete(item)
    }

    func rename(_ item: FileItem, to name: String) throws -> URL {
        try store.rename(item, to: name)
    }

    func validateRename(_ item: FileItem, to name: String) -> FileStoreError? {
        store.validateRename(item, to: name)
    }
}
