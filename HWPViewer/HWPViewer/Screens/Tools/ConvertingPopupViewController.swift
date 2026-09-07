//
//  ConvertingPopupViewController.swift
//  HWPViewer
//
//  Converting popup (Figma 19334-142042): white card 328pt, Lottie spinner 120pt, "Converting..." title,
//  "Please wait…" message and an X that aborts. No other buttons. The conversion runs here;
//  `onFinished` hands the outcome to the presenter, which pushes the result / error screen.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class ConvertingPopupViewController: UIViewController {
    enum Outcome {
        case success(ConvertResult)
        case failure(Error)
    }

    /// Called on the main thread when the conversion ends (unless cancelled).
    var onFinished: ((Outcome) -> Void)?

    private let source: FileItem
    private let outputName: String
    private var task: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let titleLabel = UILabel()
    private let card = UIView()
    private let dimView = UIView()

    init(source: FileItem, outputName: String) {
        self.source = source
        self.outputName = outputName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dimView.backgroundColor = AppColors.dim
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = AppMetrics.popupRadius
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        // Lottie spinner 120pt (design "loading (1) 2"), bundled as converting_loading.json.
        let spinner: UIView
        if let url = Bundle.main.url(forResource: "converting_loading", withExtension: "json") {
            spinner = SPNLottieView(url: url)
        } else {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.startAnimating()
            spinner = indicator
        }
        let spinnerHolder = UIView()
        spinnerHolder.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.size.equalTo(120)
        }

        titleLabel.text = L10n.convertConverting
        titleLabel.font = AppFonts.semibold(18)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        let messageLabel = UILabel()
        messageLabel.text = L10n.convertConvertingMessage
        messageLabel.font = AppFonts.regular(14)
        messageLabel.textColor = AppColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [spinnerHolder, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 32, left: 15, bottom: 24, right: 15)) }

        let closeButton = UIButton(type: .system)
        closeButton.setImage(Asset.Assets.App.icCancelX.image.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppColors.textSecondary
        card.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(10)
            make.size.equalTo(28)
        }

        // X aborts the conversion.
        closeButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.cancelAndClose() }
            .store(in: &cancellables)

        start()
    }

    private func cancelAndClose() {
        task?.cancel()
        task = nil
        dismiss(animated: true)
    }

    private func start() {
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            let outcome: Outcome
            do {
                let result = try await ConvertService.shared.convert(source: source, outputName: outputName) { [weak self] value in
                    // Progress shows in the title ("Converting... 47%") — the design has no bar.
                    self?.titleLabel.text = "\(L10n.convertConverting) \(Int(value * 100))%"
                }
                outcome = .success(result)
            } catch is CancellationError {
                return
            } catch {
                outcome = .failure(error)
            }
            guard !Task.isCancelled else { return }
            dismiss(animated: true) { [weak self] in self?.onFinished?(outcome) }
        }
    }
}
