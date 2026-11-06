//
//  HwpEngine.swift
//  HWPViewer
//
//  Thin helpers over HwpEditorKit: engine bootstrap, print-to-PDF, share.
//

import UIKit
import FirebaseCrashlytics
import HwpEditorKit
import SPNComponent

enum HwpEngine {
    /// Makes sure fonts are on disk and the Rust engine is initialised. Throws `HwpFontError` when offline.
    @MainActor
    static func prepare() async throws {
        try await HwpFontManager.shared.ensureFonts()
        HwpEngineBootstrap.setupIfNeeded()
        HwpEditorKitConfig.log = { logger($0) }
        // Engine panic (caught, command fails) -> Crashlytics log + non-fatal so the
        // Rust message/location shows up in the report instead of only on stderr.
        HwpEditorKitConfig.onEnginePanic = { message in
            let crashlytics = Crashlytics.crashlytics()
            crashlytics.log("rhwp panic: \(message)")
            crashlytics.setCustomValue(message, forKey: "rhwp_last_panic")
            crashlytics.record(error: NSError(
                domain: "rhwp.panic", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        }
        HwpEditorKitConfig.copyMenuTitle = L10n.viewerMenuCopy
        HwpEditorKitConfig.cutMenuTitle = L10n.viewerMenuCut
        HwpEditorKitConfig.pasteMenuTitle = L10n.viewerMenuPaste
        HwpEditorKitConfig.deleteMenuTitle = L10n.viewerMenuDelete
    }

    /// Opens the document off the main thread (a long file takes seconds to paginate).
    static func openDocument(at url: URL) async throws -> RhwpDocument {
        try await Task.detached(priority: .userInitiated) {
            try RhwpDocument(contentsOf: url)
        }.value
    }
}

enum PrintService {
    private static var isPrinting = false

    /// Open → system print sheet, pages drawn on demand (`HwpPrintPageRenderer`): the sheet comes up
    /// as soon as the document is open and the preview only draws the pages it shows. Rendering the
    /// whole document to one PDF first never finished on very long files (16 384 pages). Guards
    /// against double taps while the document opens.
    @MainActor
    static func printHwp(_ item: FileItem, from presenter: UIViewController) {
        guard !isPrinting else { return }
        isPrinting = true
        // Dimmed: a big file takes a while and the screen must not look usable meanwhile (ESI05-72).
        presenter.showLoadingHUD(true, dimsScreen: true)
        Task { @MainActor in
            defer {
                isPrinting = false
                presenter.showLoadingHUD(false)
            }
            do {
                try await HwpEngine.prepare()
            } catch {
                OfflinePopup.present(from: presenter) { PrintService.printHwp(item, from: presenter) }
                return
            }
            do {
                let document = try await HwpEngine.openDocument(at: item.url)
                presentPrintSheet(for: document, jobName: item.url.deletingPathExtension().lastPathComponent)
            } catch {
                logger("[Print] failed: \(error)")
                presenter.showToast(L10n.popupErrorTitle)
            }
        }
    }

    @MainActor
    private static func presentPrintSheet(for document: RhwpDocument, jobName: String) {
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = jobName
        controller.printInfo = info
        controller.printingItem = nil
        controller.printPageRenderer = HwpPrintPageRenderer(document: document)
        // The shared controller keeps its renderer (and the open document) until the next print.
        controller.present(animated: true) { controller, _, _ in controller.printPageRenderer = nil }
    }
}

enum ShareService {
    @MainActor
    static func share(_ url: URL, from presenter: UIViewController, sourceView: UIView? = nil) {
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = sourceView ?? presenter.view
            popover.sourceRect = sourceView?.bounds ?? CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = sourceView == nil ? [] : .any
        }
        presenter.present(activity, animated: true)
    }
}
