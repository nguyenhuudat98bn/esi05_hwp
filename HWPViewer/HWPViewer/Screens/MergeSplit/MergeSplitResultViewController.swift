//
//  MergeSplitResultViewController.swift
//  HWPViewer
//
//  Merge 4 / Split 2 (design "… – Done"): success badge, title, subtitle, the new file(s) — tap a
//  row to open it, share from the row's swipe action — then Back Home / Open (first file).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class MergeSplitResultViewController: AppBaseViewController {
    private let titleText: String
    private let subtitleText: String
    private let outputs: [DocumentOutput]
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(title: String, subtitle: String, outputs: [DocumentOutput]) {
        self.titleText = title
        self.subtitleText = subtitle
        self.outputs = outputs
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: ""))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        containerStackView.addArrangedSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 72
        tableView.register(SelectableFileCell.self, forCellReuseIdentifier: SelectableFileCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = makeHeader()
        tableView.contentInset.bottom = 100

        let home = MergeSplitUI.pillButton(L10n.convertSuccessBackHome, primary: false)
        let open = MergeSplitUI.pillButton(L10n.convertSuccessOpen)
        let buttons = UIStackView(arrangedSubviews: [home, open])
        buttons.spacing = 16
        buttons.distribution = .fillEqually
        _ = MergeSplitUI.bottomBar(in: view, content: buttons)
        home.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.goToAllFiles() }
            .store(in: &cancellables)
        open.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.open(index: 0) }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        RatePromptManager.shared.recordSuccess(.convertSuccess, from: self)
    }

    /// The flow is finished: Back / X behaves like Back Home.
    override func backButtonTapped() {
        goToAllFiles()
    }

    private func makeHeader() -> UIView {
        let badge = SuccessBadgeView()
        badge.snp.makeConstraints { $0.size.equalTo(132) }
        let title = MergeSplitUI.label(titleText, font: AppFonts.semibold(18), lines: 0)
        let subtitle = MergeSplitUI.label(subtitleText, font: AppFonts.regular(14), color: AppColors.textSecondary, lines: 0)
        [title, subtitle].forEach { $0.textAlignment = .center }
        let stack = UIStackView(arrangedSubviews: [badge, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(20, after: badge)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 260))
        header.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(24)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
        return header
    }

    private func open(index: Int) {
        guard outputs.indices.contains(index), let item = FileStore.shared.item(at: outputs[index].url) else { return }
        FileStore.shared.markOpened(item.url)
        let viewer = HwpViewerViewController(item: item, startInEditMode: false)
        // Leaving the viewer returns to Tools, not back into the finished flow.
        var stack = navigationController?.viewControllers ?? []
        if let firstFlowScreen = stack.firstIndex(where: { $0 is MergeSelectViewController || $0 is SelectFileViewController }) {
            stack.removeSubrange(firstFlowScreen...)
        }
        stack.append(viewer)
        navigationController?.setViewControllers(stack, animated: true)
    }
}

extension MergeSplitResultViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { outputs.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectableFileCell.identifier, for: indexPath) as! SelectableFileCell
        let output = outputs[indexPath.row]
        let size = ByteCountFormatter.string(fromByteCount: output.size, countStyle: .file)
        let meta = output.sourcePages.map { L10n.splitPartMeta($0, size) } ?? "\(output.pageCount) pages · \(size)"
        cell.configure(name: output.name, meta: meta, kind: FileKind(url: output.url) ?? .hwp, order: nil, showsSelection: false)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        open(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: L10n.fileActionShare) { [weak self] _, _, done in
            guard let self else { return done(false) }
            ShareService.share(outputs[indexPath.row].url, from: self)
            done(true)
        }
        share.backgroundColor = AppColors.primary
        return UISwipeActionsConfiguration(actions: [share])
    }
}
