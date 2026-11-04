//
//  SplitViewController.swift
//  HWPViewer
//
//  Split 1 (design "Split 1 – By page ranges" / "Split 1b – Pick pages"): source file, mode
//  (Page ranges | Pick pages | Every N), page thumbnails (part color bands, or pick checks), the
//  mode's controls, then Split / Extract → progress popup → result.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class SplitViewController: AppBaseViewController {
    private let item: FileItem
    private var plan = SplitPlan(pageCount: 1)
    private var renderer: HwpPageThumbnailRenderer?
    /// Range rows whose fields do not form a valid range right now.
    private var invalidRows = Set<Int>()

    private let modeControl = MergeSplitUI.segmented([L10n.splitModeRanges, L10n.splitModePick, L10n.splitModeEvery])
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let panelScroll = UIScrollView()
    private let panelStack = UIStackView()
    private let sourceMeta = MergeSplitUI.label(font: AppFonts.regular(12), color: AppColors.textSecondary)
    private let actionButton = MergeSplitUI.pillButton("")
    private var stripHeight: Constraint?
    private var pickPanelHeight: Constraint?

    init(item: FileItem) {
        self.item = item
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: L10n.splitTitle))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        modeControl.selectedSegmentIndexPublisher
            .sink { [weak self] index in
                guard let self, let mode = SplitPlan.Mode(rawValue: index) else { return }
                view.endEditing(true)
                plan.mode = mode
                render()
            }
            .store(in: &cancellables)
        actionButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.runSplit() }
            .store(in: &cancellables)
        load()
    }

    private func load() {
        showLoadingHUD(true)
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await HwpEngine.prepare()
                let renderer = HwpPageThumbnailRenderer(url: item.url)
                let count = try await renderer.open()
                self.renderer = renderer
                plan = SplitPlan(pageCount: count)
                sourceMeta.text = "\(count) pages · \(item.sizeText)"
                showLoadingHUD(false)
                render()
            } catch {
                showLoadingHUD(false)
                ErrorPopup.present(from: self, message: error.localizedDescription) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        let icon = FileKindIconView()
        icon.kind = item.kind
        icon.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(36)
        }
        let name = MergeSplitUI.label(item.name, font: AppFonts.medium(15))
        name.lineBreakMode = .byTruncatingMiddle
        let text = UIStackView(arrangedSubviews: [name, sourceMeta])
        text.axis = .vertical
        text.spacing = 2
        let source = UIStackView(arrangedSubviews: [icon, text])
        source.spacing = 12
        source.alignment = .center
        source.isLayoutMarginsRelativeArrangement = true
        source.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        source.layer.cornerRadius = AppMetrics.cardRadius
        source.layer.borderWidth = 1
        source.layer.borderColor = AppColors.divider.cgColor

        collectionView.backgroundColor = .clear
        collectionView.register(SplitPageCell.self, forCellWithReuseIdentifier: SplitPageCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        panelStack.axis = .vertical
        panelStack.spacing = 8
        panelScroll.addSubview(panelStack)
        panelStack.snp.makeConstraints { make in
            make.edges.equalTo(panelScroll.contentLayoutGuide).inset(UIEdgeInsets(top: 4, left: 16, bottom: 16, right: 16))
            make.width.equalTo(panelScroll.frameLayoutGuide).offset(-32)
        }

        let note = MergeSplitUI.label(L10n.splitParagraphNote, font: AppFonts.regular(12), color: UIColor(hex: "#535862"), lines: 0)
        let footer = UIStackView(arrangedSubviews: [note, actionButton])
        footer.axis = .vertical
        footer.spacing = 10
        let bar = MergeSplitUI.bottomBar(in: view, content: footer)

        let content = UIView()
        containerStackView.addArrangedSubview(content)
        [source, modeControl, collectionView, panelScroll].forEach(content.addSubview)
        source.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
        modeControl.snp.makeConstraints { make in
            make.top.equalTo(source.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(modeControl.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            stripHeight = make.height.equalTo(104).constraint
        }
        panelScroll.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bar.snp.top)
            pickPanelHeight = make.height.equalTo(72).constraint
        }
        pickPanelHeight?.deactivate()
    }

    /// Re-applies the plan to every view (mode switch, load, add / remove a part).
    private func render() {
        let isPick = plan.mode == .pick
        let layout = UICollectionViewFlowLayout()
        if isPick {
            let width = floor((view.bounds.width - 32 - 30) / 4)
            layout.scrollDirection = .vertical
            layout.itemSize = CGSize(width: width, height: width * 1.35 + 20)
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 12
        } else {
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 56, height: 96)
            layout.minimumLineSpacing = 8
        }
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.setCollectionViewLayout(layout, animated: false)
        if isPick { stripHeight?.deactivate(); pickPanelHeight?.activate() } else { pickPanelHeight?.deactivate(); stripHeight?.activate() }
        collectionView.reloadData()
        rebuildPanel()
        updateFooter()
    }

    private func updateFooter() {
        actionButton.setTitle(plan.actionTitle, for: .normal)
        actionButton.isEnabled = plan.isValid && invalidRows.isEmpty
        actionButton.alpha = actionButton.isEnabled ? 1 : 0.5
    }
}

// MARK: - Mode panels

private extension SplitViewController {
    func rebuildPanel() {
        panelStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        invalidRows.removeAll()
        switch plan.mode {
        case .ranges:
            panelStack.addArrangedSubview(MergeSplitUI.label(L10n.splitParts, font: AppFonts.semibold(16)))
            for (index, range) in plan.ranges.enumerated() {
                let row = SplitRangeRowView(index: index, range: range, editable: true)
                row.onChange = { [weak self] first, last in self?.rangeChanged(index, first, last) }
                row.onRemove = { [weak self] in self?.removeRange(index) }
                panelStack.addArrangedSubview(row)
            }
            let add = MergeSplitUI.dashedAddButton(L10n.splitAddRange)
            add.addTarget(self, action: #selector(addRange), for: .touchUpInside)
            panelStack.addArrangedSubview(add)
        case .every:
            let label = MergeSplitUI.label(L10n.splitEveryLabel(plan.pagesPerFile), font: AppFonts.semibold(16))
            let stepper = UIStepper()
            stepper.minimumValue = 1
            stepper.maximumValue = Double(plan.pageCount)
            stepper.value = Double(plan.pagesPerFile)
            stepper.addTarget(self, action: #selector(pagesPerFileChanged(_:)), for: .valueChanged)
            panelStack.addArrangedSubview(UIStackView(arrangedSubviews: [label, UIView(), stepper]))
            for (index, range) in plan.parts.enumerated() {
                panelStack.addArrangedSubview(SplitRangeRowView(index: index, range: range, editable: false))
            }
        case .pick:
            let title = MergeSplitUI.label(L10n.splitOnePerPage, font: AppFonts.medium(15))
            let hint = MergeSplitUI.label(L10n.splitOnePerPageHint, font: AppFonts.regular(12), color: UIColor(hex: "#535862"))
            let text = UIStackView(arrangedSubviews: [title, hint])
            text.axis = .vertical
            let toggle = UISwitch()
            toggle.isOn = plan.onePerPage
            toggle.onTintColor = AppColors.primary
            toggle.addTarget(self, action: #selector(onePerPageChanged(_:)), for: .valueChanged)
            let row = UIStackView(arrangedSubviews: [text, toggle])
            row.alignment = .center
            panelStack.addArrangedSubview(row)
        }
    }

    func rangeChanged(_ index: Int, _ first: Int?, _ last: Int?) {
        if let first, let last, first >= 1, first <= last, last <= plan.pageCount {
            plan.ranges[index] = first...last
            invalidRows.remove(index)
        } else {
            invalidRows.insert(index)
        }
        collectionView.reloadData()
        updateFooter()
    }

    func removeRange(_ index: Int) {
        guard plan.ranges.count > 1 else { return }
        plan.ranges.remove(at: index)
        render()
    }

    @objc func addRange() {
        let start = min((plan.ranges.last?.upperBound ?? 0) + 1, plan.pageCount)
        plan.ranges.append(start...plan.pageCount)
        render()
    }

    @objc func pagesPerFileChanged(_ stepper: UIStepper) {
        plan.pagesPerFile = Int(stepper.value)
        render()
    }

    @objc func onePerPageChanged(_ toggle: UISwitch) {
        plan.onePerPage = toggle.isOn
        updateFooter()
    }
}

// MARK: - Run

private extension SplitViewController {
    func runSplit() {
        view.endEditing(true)
        guard plan.isValid, invalidRows.isEmpty else { showToast(L10n.splitInvalidRange); return }
        let item = item
        let plan = plan
        let popup = TaskProgressPopupViewController<[DocumentOutput]>(title: L10n.splitProgress, symbol: "scissors") { report in
            let step: (Int, Int) -> Void = { index, total in
                report(Double(index - 1) / Double(max(total, 1)), L10n.splitProgressStep(index, total))
            }
            if plan.mode == .pick {
                return try await HwpMergeSplitService.shared.extract(item, pages: Array(plan.picked), onePerPage: plan.onePerPage, progress: step)
            }
            return try await HwpMergeSplitService.shared.split(item, ranges: plan.parts, progress: step)
        }
        popup.onFinished = { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let outputs):
                let done = MergeSplitResultViewController(
                    title: L10n.splitDone(outputs.count), subtitle: L10n.splitDoneSubtitle(item.name), outputs: outputs)
                navigationController?.pushViewController(done, animated: true)
            case .failure(let error):
                logger("[Split] failed: \(error)")
                ErrorPopup.present(from: self, message: error.localizedDescription)
            }
        }
        present(popup, animated: true)
    }
}

extension SplitViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        renderer == nil ? 0 : plan.pageCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SplitPageCell.identifier, for: indexPath) as! SplitPageCell
        let page = indexPath.item + 1
        let picked: Bool? = plan.mode == .pick ? plan.picked.contains(page) : nil
        cell.configure(page: page, partColor: plan.partColor(of: page), picked: picked, renderer: renderer)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard plan.mode == .pick else { return }
        let page = indexPath.item + 1
        if plan.picked.contains(page) { plan.picked.remove(page) } else { plan.picked.insert(page) }
        collectionView.reloadItems(at: [indexPath])
        updateFooter()
    }
}
