//
//  MergeFilesViewController.swift
//  HWPViewer
//
//  "Merge Files" (Figma 6978:108131, empty 6978:108423): the picked files in merge order under a
//  "Long press to sort manually" strip — long-press a row to drag it, red trash removes it — a blue
//  + button to pick more, and "Merge (n)" at the bottom (needs 2+ files). Empty list → box art +
//  "No files yet. Add file to merge", the + button stays, no bottom bar.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class MergeFilesViewController: AppBaseViewController, ToolFlowScreen {
    private var files: [FileItem]
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let hintBar = UIView()
    private let emptyView = MergeSplitUI.emptyState(text: L10n.mergeEmpty)
    private let addButton = MergeSplitUI.addButton(accessibilityLabel: L10n.mergeAddFiles)
    private let mergeButton = MergeSplitUI.primaryButton("")
    private var bottomBar: UIView?

    init(files: [FileItem]) {
        self.files = files
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: L10n.mergeFilesTitle))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        MergeSplitUI.addNavHairline(to: navigationView)
        buildHintBar()
        containerStackView.addArrangedSubview(hintBar)
        containerStackView.addArrangedSubview(tableView)
        containerStackView.addArrangedSubview(nativeAdSlot) // above the Merge bar

        tableView.backgroundColor = AppColors.background
        tableView.separatorStyle = .none
        tableView.rowHeight = HwpFileRowCell.height
        tableView.contentInset.top = 10 // + the row's own 6pt gap = 16pt under the strip
        tableView.register(HwpFileRowCell.self, forCellReuseIdentifier: HwpFileRowCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        // Long press lifts a row (drag & drop inside the table) — "Long press to sort manually".
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self

        buildEmptyView()
        bottomBar = MergeSplitUI.bottomBar(in: containerStackView, of: view, content: mergeButton)
        setupAdvertiser(on: .mergeFiles)
        mergeButton.tapPublisher
            .sink { [weak self] _ in self?.askFileName() }
            .store(in: &cancellables)
        buildAddButton()
        refresh()
    }

    // MARK: - Layout

    /// 40pt #F5F5F6 strip: sort glyph 16pt + 12pt hint.
    private func buildHintBar() {
        hintBar.backgroundColor = AppColors.hintBarBackground
        let icon = UIImageView(image: Asset.Assets.App.icSortHint.image)
        let label = MergeSplitUI.label(L10n.mergeSortHint, font: AppFonts.regular(12), color: AppColors.textSecondary)
        hintBar.addSubview(icon)
        hintBar.addSubview(label)
        hintBar.snp.makeConstraints { $0.height.equalTo(40) }
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }
    }

    /// Box illustration 165×140 + 14pt hint, centred in the list area.
    private func buildEmptyView() {
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
        MergeSplitUI.centerEmptyState(emptyView, onScreenOf: view)
    }

    /// 52pt blue round button, 16pt from the right, 48pt above the bottom bar — same spot when the
    /// list is empty and the bar is hidden (Figma 6978:108525). Always 48pt above the end of the list,
    /// so a native ad under the list pushes it up instead of being covered.
    private func buildAddButton() {
        view.addSubview(addButton)
        MergeSplitUI.pinAddButton(addButton, in: view, above: tableView)
        addButton.tapPublisher
            .sink { [weak self] _ in self?.addFiles() }
            .store(in: &cancellables)
    }

    private func refresh() {
        let isEmpty = files.isEmpty
        // The table stays in the stack (it is the flexible row); the empty view covers it.
        emptyView.isHidden = !isEmpty
        hintBar.isHidden = isEmpty
        bottomBar?.isHidden = isEmpty
        mergeButton.setTitle(L10n.mergeAction(files.count), for: .normal)
        mergeButton.isEnabled = files.count >= 2
        tableView.contentInset.bottom = 52 + 48 // the last row can scroll clear of the + button
    }

    // MARK: - Actions

    /// By row, not by file: the same file may sit in the merge twice.
    private func remove(at index: Int) {
        guard files.indices.contains(index) else { return }
        files.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        refresh()
    }

    /// The picker opens with nothing ticked and its picks go to the end of the list, so a file already
    /// in the merge can be added again to merge a file with itself (ESI05-55).
    private func addFiles() {
        let picker = HwpFilePickerViewController(mode: .multiple(minimum: 1))
        picker.onPicked = { [weak self] picked in
            guard let self else { return }
            files += picked
            tableView.reloadData()
            refresh()
            navigationController?.popToViewController(self, animated: true)
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    private func askFileName() {
        guard files.count >= 2 else { return }
        let dialog = RenameDialog(title: L10n.mergeFileNameTitle, initialName: "", confirmTitle: L10n.popupOk)
        dialog.validator = { FileStore.shared.validateNewName($0, ext: "hwp")?.errorDescription }
        dialog.onConfirm = { [weak self] name in
            self?.runMerge(outputName: name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        present(dialog, animated: true)
    }

    private func runMerge(outputName: String) {
        let files = files
        let loading = LoadingOverlayViewController(
            work: { [try await HwpMergeSplitService.shared.merge(files, outputName: outputName)] },
            onFinished: { [weak self] result in self?.finish(result) }
        )
        present(loading, animated: true)
    }

    private func finish(_ result: Result<[DocumentOutput], Error>) {
        switch result {
        case .success(let outputs):
            guard let output = outputs.first else { return }
            let done = ConvertResultViewController(outputURL: output.url, size: output.size, title: L10n.mergeSuccessTitle,
                                                   titleFont: AppFonts.semibold(18), place: .mergeSplit,
                                                   nativePlace: .mergeResult)
            navigationController?.pushViewController(done, animated: true)
        case .failure(let error):
            ErrorPopup.present(from: self, message: ErrorPopup.message(for: error))
        }
    }
}

// MARK: - Table

extension MergeFilesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { files.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HwpFileRowCell.identifier, for: indexPath) as! HwpFileRowCell
        let item = files[indexPath.row]
        cell.configure(item: item, accessory: .delete)
        cell.onDelete = { [weak self, weak cell] in
            guard let self, let cell, let row = tableView.indexPath(for: cell)?.row else { return }
            remove(at: row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = files.remove(at: sourceIndexPath.row)
        files.insert(item, at: destinationIndexPath.row)
    }
}

// MARK: - Long-press reorder (drag & drop within the table)

extension MergeFilesViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let provider = NSItemProvider(object: files[indexPath.row].id as NSString)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = files[indexPath.row].id
        return [item]
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        // The 62pt row inside the 74pt cell (cell coordinates).
        let row = CGRect(x: 0, y: AppMetrics.cellSpacing / 2, width: tableView.bounds.width, height: AppMetrics.cellHeight)
        parameters.visiblePath = UIBezierPath(roundedRect: row, cornerRadius: AppMetrics.cellRadius)
        return parameters
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard session.localDragSession != nil else { return UITableViewDropProposal(operation: .forbidden) }
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    /// Moves are applied by `moveRowAt` (local drag), nothing to read from the session.
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {}
}
