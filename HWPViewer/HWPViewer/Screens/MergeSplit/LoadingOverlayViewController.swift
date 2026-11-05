//
//  LoadingOverlayViewController.swift
//  HWPViewer
//
//  "Loading" state of Merge / Split / OCR (Figma 6978:109119 / 6978:110688 / 6988:130059): the screen dimmed with the
//  app overlay colour and a 160pt spinner in the middle — no card, no text, not cancellable.
//  The spinner is the project's shared loading Lottie (`converting_loading.json`, also used by the
//  Convert popup).
//

import UIKit
import SnapKit
import SPNComponent

/// Screens the reopen (app-open) ad must not cover: the work behind them is not cancellable and the
/// screen has to close itself when it is done (see `AppDelegate.makeOnboardingCoordinator`).
protocol BlocksReopenAd: UIViewController {}

final class LoadingOverlayViewController<Output>: UIViewController, BlocksReopenAd {
    private let work: () async throws -> Output
    private let onFinished: (Result<Output, Error>) -> Void
    /// `viewDidAppear` runs again whenever a full-screen ad presented on top goes away: start once.
    private var didStart = false
    /// Result waiting for whatever is presented on top (an ad) to close first.
    private var pendingResult: Result<Output, Error>?

    init(work: @escaping () async throws -> Output,
         onFinished: @escaping (Result<Output, Error>) -> Void) {
        self.work = work
        self.onFinished = onFinished
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.dim
        let spinner: UIView
        if let url = Bundle.main.url(forResource: "converting_loading", withExtension: "json") {
            spinner = SPNLottieView(url: url)
        } else {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .white
            indicator.startAnimating()
            spinner = indicator
        }
        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(160)
        }
        view.accessibilityViewIsModal = true
        spinner.isAccessibilityElement = true
        spinner.accessibilityLabel = L10n.mergeSplitLoading
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pendingResult {
            // Back on top after an ad: finish now.
            finish(pendingResult)
            return
        }
        guard !didStart else { return }
        didStart = true
        UIAccessibility.post(notification: .screenChanged, argument: view.subviews.first)
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result: Result<Output, Error>
            do {
                result = .success(try await work())
            } catch {
                result = .failure(error)
            }
            finish(result)
        }
    }

    /// Closes the overlay, then reports. With something presented on top, `dismiss` would close that
    /// instead (and the spinner would stay): wait for it to go, `viewDidAppear` calls back here.
    private func finish(_ result: Result<Output, Error>) {
        guard presentedViewController == nil else {
            pendingResult = result
            return
        }
        pendingResult = nil
        let onFinished = onFinished
        presentingViewController?.dismiss(animated: true) { onFinished(result) }
    }
}
