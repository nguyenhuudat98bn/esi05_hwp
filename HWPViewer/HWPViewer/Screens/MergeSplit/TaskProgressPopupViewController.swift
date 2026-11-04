//
//  TaskProgressPopupViewController.swift
//  HWPViewer
//
//  Center popup with a progress bar for a long engine job (Merge 3 / Split progress in the design):
//  icon, title, a step line, bar + percent, Cancel. Runs `work` as a Task; Cancel cancels it.
//  `onFinished` gets the result after the popup has dismissed (not called on cancel).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

final class TaskProgressPopupViewController<Output>: UIViewController {
    /// Reports progress: fraction 0…1 and an optional step line. Call on the main thread.
    typealias Reporter = (Double, String?) -> Void

    var onFinished: ((Result<Output, Error>) -> Void)?

    private let titleText: String
    private let symbol: String
    private let work: (@escaping Reporter) async throws -> Output
    private var task: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let stepLabel = MergeSplitUI.label(" ", font: AppFonts.regular(14), color: AppColors.textSecondary, lines: 2)
    private let percentLabel = MergeSplitUI.label("0%", font: AppFonts.semibold(12))
    private let bar = UIProgressView(progressViewStyle: .bar)

    init(title: String, symbol: String, work: @escaping (@escaping Reporter) async throws -> Output) {
        self.titleText = title
        self.symbol = symbol
        self.work = work
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.dim
        let card = UIView()
        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = AppMetrics.popupRadius
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(31)
        }

        let iconCircle = UIView()
        iconCircle.backgroundColor = AppColors.primarySoft
        iconCircle.layer.cornerRadius = 44
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = AppColors.primary
        icon.contentMode = .scaleAspectFit
        iconCircle.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(44)
        }
        iconCircle.snp.makeConstraints { $0.size.equalTo(88) }

        let title = MergeSplitUI.label(titleText, font: AppFonts.semibold(18), lines: 0)
        title.textAlignment = .center
        stepLabel.textAlignment = .center

        bar.trackTintColor = AppColors.divider
        bar.progressTintColor = AppColors.primary
        bar.layer.cornerRadius = 4
        bar.clipsToBounds = true
        bar.snp.makeConstraints { $0.height.equalTo(8) }
        let percentRow = UIStackView(arrangedSubviews: [UIView(), percentLabel])
        let barStack = UIStackView(arrangedSubviews: [bar, percentRow])
        barStack.axis = .vertical
        barStack.spacing = 6

        let cancel = MergeSplitUI.pillButton(L10n.popupCancel, primary: false)
        cancel.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.cancelAndClose() }
            .store(in: &cancellables)

        let stack = UIStackView(arrangedSubviews: [iconCircle, title, stepLabel, barStack, cancel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.setCustomSpacing(6, after: title)
        [title, stepLabel, barStack, cancel].forEach { $0.snp.makeConstraints { $0.width.equalToSuperview() } }
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 32, left: 20, bottom: 24, right: 20)) }

        start()
    }

    private func start() {
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            let result: Result<Output, Error>
            do {
                let output = try await work { [weak self] fraction, step in
                    self?.update(fraction: fraction, step: step)
                }
                update(fraction: 1, step: nil)
                result = .success(output)
            } catch {
                result = .failure(error)
            }
            guard !Task.isCancelled else { return }
            dismiss(animated: true) { [weak self] in self?.onFinished?(result) }
        }
    }

    private func update(fraction: Double, step: String?) {
        let clamped = Float(min(max(fraction, 0), 1))
        bar.setProgress(clamped, animated: true)
        percentLabel.text = "\(Int((clamped * 100).rounded()))%"
        if let step { stepLabel.text = step }
    }

    private func cancelAndClose() {
        task?.cancel()
        task = nil
        dismiss(animated: true)
    }
}
