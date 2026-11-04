//
//  HwpFilePickerViewController.swift
//  HWPViewer
//
//  "Select Files" (Merge, Figma 6978:106911 / 107642 / 107869) and "Select a file" (Split, 6978:109511):
//  nav title, search pill, every HWP/HWPX in the app.
//  - `.multiple`: checkbox per row + select-all in the nav, "Continue (n)" bottom button (gray at 0).
//    Picks keep tap order — that is the merge order on the next screen.
//  - `.single`: plain rows, tapping one picks it.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class HwpFilePickerViewController: AppBaseViewController, ToolFlowScreen {
    enum Mode {
        /// `preselected`: files already in the merge (kept checked and in their order).
        case multiple(preselected: [FileItem])
        case single
    }

    /// Multiple: the picked files in pick order. Single: one file.
    var onPicked: (([FileItem]) -> Void)?

    private let mode: Mode
    private let viewModel = FileListViewModel(filter: .family(.hwp))
    private let searchField = FileSearchField()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let selectAll = SelectAllButton(type: .custom)
    private let continueButton = MergeSplitUI.primaryButton("")
    private var items: [FileItem] = []
    /// Picked file ids (`FileItem.id`) in pick order, across searches.
    private var picked: [String] = []
    /// Every picked item seen so far, so a pick hidden by the search query is still returned.
    private var pickedItems: [String: FileItem] = [:]

    private var isMultiple: Bool {
        if case .multiple = mode { return true }
        return false
    }

    init(mode: Mode) {
        self.mode = mode
        let title: String
        if case .multiple(let preselected) = mode {
            picked = preselected.map(\.id)
            pickedItems = Dictionary(preselected.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            title = L10n.mergeSelectFiles
        } else {
            title = L10n.splitSelectFile
        }
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: title))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        MergeSplitUI.addNavHairline(to: navigationView)

        let searchHolder = UIView()
        searchHolder.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalToSuperview().inset(10) // + the row's own 6pt top gap = 16pt to the first row
        }
        containerStackView.addArrangedSubview(searchHolder)
        containerStackView.addArrangedSubview(tableView)

        tableView.backgroundColor = AppColors.background
        tableView.separatorStyle = .none
        tableView.rowHeight = HwpFileRowCell.height
        tableView.keyboardDismissMode = .onDrag
        tableView.register(HwpFileRowCell.self, forCellReuseIdentifier: HwpFileRowCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self

        if isMultiple {
            selectAll.install(in: navigationView)
            selectAll.tapPublisher
                .sink { [weak self] _ in self?.toggleSelectAll() }
                .store(in: &cancellables)
            MergeSplitUI.bottomBar(in: view, content: continueButton)
            tableView.contentInset.bottom = MergeSplitUI.bottomBarHeight
            continueButton.tapPublisher
                .sink { [weak self] _ in self?.finish() }
                .store(in: &cancellables)
        }

        searchField.textField.textPublisher
            .map { $0 ?? "" }
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] query in self?.viewModel.query = query }
            .store(in: &cancellables)
        searchField.textField.controlEventPublisher(for: .editingDidEndOnExit)
            .sink { [weak self] _ in self?.searchField.textField.resignFirstResponder() }
            .store(in: &cancellables)

        viewModel.$items.receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.items = items
                items.forEach { item in if self.pickedItems[item.id] != nil { self.pickedItems[item.id] = item } }
                tableView.reloadData()
                refreshSelectionUI()
            }
            .store(in: &cancellables)
    }

    private func toggle(_ item: FileItem) {
        if let index = picked.firstIndex(of: item.id) {
            picked.remove(at: index)
            pickedItems[item.id] = nil
        } else {
            picked.append(item.id)
            pickedItems[item.id] = item
        }
        tableView.reloadData()
        refreshSelectionUI()
    }

    /// Select all = every visible (searched) file; when they are all picked, un-pick them.
    private func toggleSelectAll() {
        let visible = items.map(\.id)
        if !visible.isEmpty, visible.allSatisfy(picked.contains) {
            picked.removeAll { visible.contains($0) }
            visible.forEach { pickedItems[$0] = nil }
        } else {
            for item in items where !picked.contains(item.id) {
                picked.append(item.id)
                pickedItems[item.id] = item
            }
        }
        tableView.reloadData()
        refreshSelectionUI()
    }

    private func refreshSelectionUI() {
        guard isMultiple else { return }
        continueButton.setTitle(L10n.mergeContinue(picked.count), for: .normal)
        continueButton.isEnabled = !picked.isEmpty
        selectAll.isOn = !items.isEmpty && items.allSatisfy { picked.contains($0.id) }
    }

    private func finish() {
        let result = picked.compactMap { pickedItems[$0] }
        guard !result.isEmpty else { return }
        onPicked?(result)
    }
}

extension HwpFilePickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HwpFileRowCell.identifier, for: indexPath) as! HwpFileRowCell
        let item = items[indexPath.row]
        cell.configure(item: item, accessory: isMultiple ? .checkbox(isOn: picked.contains(item.id)) : .none)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if isMultiple {
            toggle(item)
        } else {
            onPicked?([item])
        }
    }
}
