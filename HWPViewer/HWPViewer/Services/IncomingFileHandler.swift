//
//  IncomingFileHandler.swift
//  HWPViewer
//
//  "Open in HWP Viewer" from Files / Mail: copy into Documents and open the viewer once Home is up.
//

import UIKit
import SPNComponent

final class IncomingFileHandler {
    static let shared = IncomingFileHandler()
    private var pending: URL?

    func handle(_ url: URL) {
        do {
            let imported = try FileStore.shared.importFile(from: url, allowed: FileKind.hwpExtensions)
            pending = imported
            tryOpen()
        } catch {
            logger("[Incoming] import failed: \(error)")
        }
    }

    /// Called by Home when it appears so a cold-start open lands after onboarding.
    func tryOpen() {
        guard let url = pending,
              let nav = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow) })
                .first?.rootViewController as? UINavigationController,
              nav.viewControllers.first is MainTabBarController,
              let item = FileStore.shared.item(at: url) else { return }
        pending = nil
        FileStore.shared.markOpened(item.url)
        nav.pushViewController(HwpViewerViewController(item: item), animated: true)
    }
}
