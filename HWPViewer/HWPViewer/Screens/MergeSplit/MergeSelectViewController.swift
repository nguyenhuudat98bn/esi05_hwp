//
//  MergeSelectViewController.swift
//  HWPViewer
//
//  Merge 1 (design "Merge 1 – Select files"): every HWP/HWPX in the app; tapping a row adds it to
//  the merge in tap order (badge 1, 2, 3…), tapping again removes it. Next (2+ files) → Merge 2.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class MergeSelectViewController: AppBaseViewController {
    private let viewModel = FileListViewModel(filter: .family(.hwp))
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let countLabel = MergeSplitUI.label(font: AppFonts.semibold(14))
    private let nextButton = MergeSplitUI.pillButton(L10n.mergeNext)
    private var items: [FileItem] = []
    /// Picked file ids in pick order.
    private var picked: [String] = []

    init() {
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: L10n.mergeTitle))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let hint = MergeSplitUI.label(L10n.mergeSelectHint, font: AppFonts.regular(14), color: UIColor(hex: "#535862"), lines: 0)
        let hintHolder = UIView()
        hintHolder.addSubview(hint)
        hint.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 4, right: 16)) }
        containerStackView.addArrangedSubview(hintHolder)
        containerStackView.addArrangedSubview(tableView)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 70
        tableView.register(SelectableFileCell.self, forCellReuseIdentifier: SelectableFileCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self

        let footer = UIStackView(arrangedSubviews: [countLabel, nextButton])
        footer.axis = .vertical
        footer.spacing = 10
        let bar = MergeSplitUI.bottomBar(in: view, content: footer)
        tableView.contentInset.bottom = 120
        bar.layoutIfNeeded()

        viewModel.$items.receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.items = items
                picked.removeAll { id in !items.contains { $0.id == id } }
                refresh()
            }
            .store(in: &cancellables)
        nextButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.goNext() }
            .store(in: &cancellables)
    }

    private func refresh() {
        tableView.reloadData()
        countLabel.text = L10n.mergeSelectedCount(picked.count)
        nextButton.isEnabled = picked.count >= 2
        nextButton.alpha = nextButton.isEnabled ? 1 : 0.5
    }

    private func goNext() {
        let files = picked.compactMap { id in items.first { $0.id == id } }
        guard files.count >= 2 else { return }
        let order = MergeOrderViewController(files: files)
        // Removing a file on the next screen un-picks it here, so Back shows the same selection.
        order.onFilesChanged = { [weak self] files in
            self?.picked = files.map(\.id)
            self?.refresh()
        }
        navigationController?.pushViewController(order, animated: true)
    }
}

extension MergeSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectableFileCell.identifier, for: indexPath) as! SelectableFileCell
        let item = items[indexPath.row]
        let order = picked.firstIndex(of: item.id).map { $0 + 1 }
        cell.configure(name: item.name, meta: item.metaText, kind: item.kind, order: order)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = items[indexPath.row].id
        if let index = picked.firstIndex(of: id) {
            picked.remove(at: index)
        } else {
            picked.append(id)
        }
        refresh()
    }
}
