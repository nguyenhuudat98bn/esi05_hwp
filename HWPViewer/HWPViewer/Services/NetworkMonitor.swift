//
//  NetworkMonitor.swift
//  HWPViewer
//
//  Watches connectivity and shows the "You're Offline" dialog (Figma D1) wherever the user happens
//  to be when the connection drops. Reading a file works offline, but fonts, conversion and ads all
//  need the network, so QA asks for the dialog app-wide rather than only at the point of failure.
//

import UIKit
import Network
import SPNComponent

@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.spn.hwpviewer.network-monitor")
    private var isOnline = true
    /// Set while the dialog is up, and cleared when the connection comes back. A user who taps
    /// "Later" while still offline is not nagged again until connectivity actually returns and
    /// drops once more.
    private var didWarn = false
    private var started = false

    private init() {}

    var isConnected: Bool { isOnline }

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor [weak self] in self?.handle(isOnline: online) }
        }
        monitor.start(queue: queue)
    }

    private func handle(isOnline online: Bool) {
        let wasOnline = isOnline
        isOnline = online
        if online {
            didWarn = false
            return
        }
        // Only the online -> offline edge, so a flapping connection cannot stack dialogs.
        guard wasOnline, !didWarn else { return }
        presentOfflinePopup()
    }

    private func presentOfflinePopup() {
        guard let presenter = Self.topViewController() else { return }
        // An ad, the system picker or another alert owns the screen — don't fight it.
        guard presenter.presentedViewController == nil, presenter is AppAlertViewController == false else { return }
        didWarn = true
        OfflinePopup.present(from: presenter) { [weak self] in
            guard let self, !self.isOnline else { return }
            // "Try Again" and still down: say so again.
            self.didWarn = false
            self.presentOfflinePopup()
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}
