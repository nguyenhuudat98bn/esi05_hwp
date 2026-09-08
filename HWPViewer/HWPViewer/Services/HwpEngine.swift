//
//  HwpEngine.swift
//  HWPViewer
//
//  Thin helpers over HwpEditorKit: engine bootstrap, print-to-PDF, share.
//

import UIKit
import HwpEditorKit
import SPNComponent

enum HwpEngine {
    /// Makes sure fonts are on disk and the Rust engine is initialised. Throws `HwpFontError` when offline.
    @MainActor
    static func prepare() async throws {
        try await HwpFontManager.shared.ensureFonts()
        HwpEngineBootstrap.setupIfNeeded()
        HwpEditorKitConfig.log = { logger($0) }
        HwpEditorKitConfig.copyMenuTitle = L10n.viewerMenuCopy
        HwpEditorKitConfig.cutMenuTitle = L10n.viewerMenuCut
        HwpEditorKitConfig.pasteMenuTitle = L10n.viewerMenuPaste
        HwpEditorKitConfig.deleteMenuTitle = L10n.viewerMenuDelete
    }

    /// Renders the whole document to a temporary PDF (UIPrintInteractionController cannot read HWP).
    static func renderPDF(from url: URL) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let doc = try RhwpDocument(contentsOf: url)
            let data = try HwpPrintPDFBuilder.buildPDF(document: doc)
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.deletingPathExtension().lastPathComponent)
                .appendingPathExtension("pdf")
            try data.write(to: tmp, options: .atomic)
            return tmp
        }.value
    }
}

enum PrintService {
    private static var isPrinting = false

    /// Render → system print sheet. Guards against double taps while rendering.
    @MainActor
    static func printHwp(_ item: FileItem, from presenter: UIViewController) {
        guard !isPrinting else { return }
        isPrinting = true
        presenter.showLoadingHUD(true)
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
                let pdfURL = try await HwpEngine.renderPDF(from: item.url)
                printPDF(at: pdfURL, from: presenter)
            } catch {
                logger("[Print] failed: \(error)")
                presenter.showToast(L10n.popupErrorTitle)
            }
        }
    }

    @MainActor
    static func printPDF(at url: URL, from presenter: UIViewController) {
        guard UIPrintInteractionController.canPrint(url) else {
            presenter.showToast(L10n.popupErrorTitle)
            return
        }
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = url.deletingPathExtension().lastPathComponent
        controller.printInfo = info
        controller.printingItem = url
        controller.present(animated: true, completionHandler: nil)
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
