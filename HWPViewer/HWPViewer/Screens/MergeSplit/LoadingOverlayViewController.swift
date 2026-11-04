//
//  LoadingOverlayViewController.swift
//  HWPViewer
//
//  "Loading" state of Merge / Split (Figma 6978:109119 / 6978:110688): the screen dimmed with the
//  app overlay colour and a 160pt spinner in the middle — no card, no text, not cancellable.
//  The spinner is the project's shared loading Lottie (`converting_loading.json`, also used by the
//  Convert popup).
//

import UIKit
import SnapKit
import SPNComponent

final class LoadingOverlayViewController: UIViewController {
    private let work: () async throws -> [DocumentOutput]
    private let onFinished: (Result<[DocumentOutput], Error>) -> Void

    init(work: @escaping () async throws -> [DocumentOutput],
         onFinished: @escaping (Result<[DocumentOutput], Error>) -> Void) {
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
        UIAccessibility.post(notification: .screenChanged, argument: view.subviews.first)
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result: Result<[DocumentOutput], Error>
            do {
                result = .success(try await work())
            } catch {
                result = .failure(error)
            }
            dismiss(animated: true) { [onFinished] in onFinished(result) }
        }
    }
}
