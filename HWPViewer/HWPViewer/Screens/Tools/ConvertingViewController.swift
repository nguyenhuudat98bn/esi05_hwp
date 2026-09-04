//
//  ConvertingViewController.swift
//  HWPViewer
//
//  G4 loading screen (no design yet): file card, progress ring, Cancel. Pushes ConvertResult on success,
//  ConvertError (G7) on failure.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class ConvertingViewController: AppBaseViewController {
    private let source: FileItem
    private let outputName: String
    private var task: Task<Void, Never>?

    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let percentLabel = UILabel()
    private let cancelButton = UIButton(type: .system)

    init(source: FileItem, outputName: String) {
        self.source = source
        self.outputName = outputName
        super.init(place: .convert, navigationConfigs: SPNNavigationConfiguration(
            title: L10n.convertTitle, hasBackButton: false,
            titleFont: AppFonts.semibold(18), titleColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        start()
    }

    private func setupViews() {
        let content = UIView()
        containerStackView.addArrangedSubview(content)

        let icon = FileKindIconView()
        icon.kind = source.kind
        let nameLabel = UILabel()
        nameLabel.text = source.displayName
        nameLabel.font = AppFonts.semibold(16)
        nameLabel.textColor = AppColors.textPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        let statusLabel = UILabel()
        statusLabel.text = L10n.convertConverting
        statusLabel.font = AppFonts.regular(14)
        statusLabel.textColor = AppColors.textSecondary
        statusLabel.textAlignment = .center

        progressView.progressTintColor = AppColors.primary
        progressView.trackTintColor = AppColors.surfaceMuted
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        percentLabel.font = AppFonts.medium(13)
        percentLabel.textColor = AppColors.textSecondary
        percentLabel.textAlignment = .center
        percentLabel.text = "0%"

        cancelButton.setTitle(L10n.popupCancel, for: .normal)
        cancelButton.titleLabel?.font = AppFonts.semibold(15)
        cancelButton.setTitleColor(AppColors.textPrimary, for: .normal)
        cancelButton.backgroundColor = AppColors.surface
        cancelButton.layer.cornerRadius = AppMetrics.buttonRadius
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = AppColors.border.cgColor

        let stack = UIStackView(arrangedSubviews: [icon, nameLabel, statusLabel, progressView, percentLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(24, after: statusLabel)
        content.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        icon.snp.makeConstraints { $0.size.equalTo(CGSize(width: 72, height: 80)) }
        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(8)
        }
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(AppMetrics.buttonHeight)
        }
        cancelButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.task?.cancel()
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
    }

    private func start() {
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await ConvertService.shared.convert(source: source, outputName: outputName) { [weak self] value in
                    self?.progressView.setProgress(Float(value), animated: true)
                    self?.percentLabel.text = "\(Int(value * 100))%"
                }
                guard !Task.isCancelled else { return }
                let resultVC = ConvertResultViewController(outputURL: result.outputURL, size: result.size)
                var stack = navigationController?.viewControllers ?? []
                stack.removeAll { $0 === self }
                stack.append(resultVC)
                navigationController?.setViewControllers(stack, animated: true)
            } catch is CancellationError {
                return
            } catch ConvertError.notAvailable {
                // Engine stub (HwpEditorKit < 1.2): informational popup, not a failure screen.
                guard !Task.isCancelled else { return }
                ErrorPopup.present(from: self, message: L10n.convertComingSoon) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } catch {
                guard !Task.isCancelled else { return }
                // G7 (Figma 19108-24632): full-screen error replaces this loading screen in the stack.
                let errorVC = ConvertErrorViewController()
                var stack = navigationController?.viewControllers ?? []
                stack.removeAll { $0 === self }
                stack.append(errorVC)
                navigationController?.setViewControllers(stack, animated: true)
            }
        }
    }
}
