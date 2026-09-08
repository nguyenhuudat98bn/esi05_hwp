//
//  FileActionsCoordinator.swift
//  HWPViewer
//
//  Shared handling of file rows: open viewer, more sheet, bookmark, rename, share, print, delete, import.
//

import UIKit
import UniformTypeIdentifiers
import SPNComponent

@MainActor
final class FileActionsCoordinator: NSObject {
    private weak var presenter: UIViewController?
    private let viewModel: FileListViewModel
    private var pendingImport: ((URL) -> Void)?
    private var pendingImportFamily: FileFamily = .hwp

    init(presenter: UIViewController, viewModel: FileListViewModel) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    // MARK: - Open

    func open(_ item: FileItem, startInEditMode: Bool = false) {
        guard let presenter else { return }
        guard item.kind.isHwp else { return }
        viewModel.markOpened(item)
        let viewer = HwpViewerViewController(item: item, startInEditMode: startInEditMode)
        // Remote `show_paywall_at` contains "view_file" → paywall (percent/max-gated) before the interstitial + viewer.
        PaywallPresenter.shared.presentIfAllowed(at: .viewFile, from: presenter) {
            SPNAdsManager.shared.interstitial.show(from: presenter, place: .home) { _ in
                presenter.navigationController?.pushViewController(viewer, animated: true)
            }
        }
    }

    // MARK: - More sheet

    func presentMore(for item: FileItem, actions: [FileAction] = [.rename, .share, .print, .delete]) {
        guard let presenter else { return }
        let sheet = FileActionSheet(item: item, actions: actions)
        sheet.onBookmark = { [weak self, weak sheet] in
            guard let self else { return }
            let added = viewModel.toggleBookmark(item)
            self.presenter?.showToast(added ? L10n.toastBookmarkAdded : L10n.toastBookmarkRemoved)
            // On the Bookmark tab the file just left the list, so the sheet is now acting on
            // something the user can no longer see — close it instead of leaving Rename/Delete
            // live on a row that vanished (ESI05-22).
            if !added, viewModel.filter == .bookmark {
                sheet?.dismiss(animated: true)
            }
        }
        sheet.onAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .edit: open(item, startInEditMode: true)
            case .rename: rename(item)
            case .share: share(item)
            case .print: print(item)
            case .delete: delete(item)
            }
        }
        presenter.present(sheet, animated: true)
    }

    func toggleBookmark(_ item: FileItem) {
        let added = viewModel.toggleBookmark(item)
        presenter?.showToast(added ? L10n.toastBookmarkAdded : L10n.toastBookmarkRemoved)
    }

    func rename(_ item: FileItem, completion: ((URL) -> Void)? = nil) {
        guard let presenter else { return }
        let dialog = RenameDialog(initialName: item.displayName, requiresChange: true)
        dialog.validator = { [weak self] name in self?.viewModel.validateRename(item, to: name)?.errorDescription }
        dialog.onConfirm = { [weak self] name in
            guard let self else { return }
            do {
                let url = try viewModel.rename(item, to: name)
                presenter.showToast(L10n.toastRenamed)
                completion?(url)
            } catch {
                ErrorPopup.present(from: presenter, message: error.localizedDescription)
            }
        }
        presenter.present(dialog, animated: true)
    }

    func share(_ item: FileItem) {
        guard let presenter else { return }
        ShareService.share(item.url, from: presenter)
    }

    func print(_ item: FileItem) {
        guard let presenter else { return }
        PrintService.printHwp(item, from: presenter)
    }

    func delete(_ item: FileItem, completion: (() -> Void)? = nil) {
        guard let presenter else { return }
        DeleteConfirmPopup.present(from: presenter, fileName: item.displayName) { [weak self] in
            guard let self else { return }
            do {
                try viewModel.delete(item)
                presenter.showToast(L10n.toastDeleted)
                completion?()
            } catch {
                ErrorPopup.present(from: presenter, message: error.localizedDescription)
            }
        }
    }

    // MARK: - Import

    /// Opens the system picker filtered to `family`; copies into Documents; opens the viewer for HWP.
    func pickAndImport(family: FileFamily, completion: ((URL) -> Void)? = nil) {
        guard let presenter else { return }
        pendingImportFamily = family
        pendingImport = completion ?? { [weak self] url in
            guard family == .hwp, let item = FileStore.shared.item(at: url) else { return }
            self?.open(item)
        }
        var types = family.utTypes
        if types.isEmpty { types = [.data] }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = self
        presenter.present(picker, animated: true)
    }
}

extension FileActionsCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let source = urls.first, let presenter else { return }
        do {
            let url = try FileStore.shared.importFile(from: source, allowed: pendingImportFamily.extensions)
            // Picked with asCopy → source is a temp copy we own; clean it.
            try? FileManager.default.removeItem(at: source)
            pendingImport?(url)
        } catch {
            ErrorPopup.present(from: presenter, message: error.localizedDescription)
        }
        pendingImport = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pendingImport = nil
    }
}
