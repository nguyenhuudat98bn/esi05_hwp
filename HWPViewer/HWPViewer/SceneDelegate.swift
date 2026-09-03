//
//  SceneDelegate.swift
//  HWPViewer
//
//  UIScene lifecycle (required by the iOS 26 SDK). Creates the window and forwards
//  active / background / open-URL events to AppDelegate, which owns the onboarding coordinator.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appDelegate: AppDelegate? { UIApplication.shared.delegate as? AppDelegate }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        appDelegate?.startUI(in: window)
        connectionOptions.urlContexts.forEach { appDelegate?.handleOpen(url: $0.url) }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { appDelegate?.handleOpen(url: $0.url) }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appDelegate?.sceneDidBecomeActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate?.sceneDidEnterBackground()
    }
}
