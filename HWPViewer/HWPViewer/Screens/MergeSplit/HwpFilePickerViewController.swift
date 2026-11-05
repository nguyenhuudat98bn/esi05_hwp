//
//  HwpFilePickerViewController.swift
//  HWPViewer
//
//  "Select Files" (Merge, Figma 6978:106911 / 107642 / 107869) and "Select a file" (Split, 6978:109511):
//  nav title, search pill, every HWP/HWPX in the app.
//  - `.multiple(minimum:)`: checkbox per row + select-all in the nav, "Continue (n)" bottom button, on
//    from `minimum` picks (2 to start a merge, 1 to add to one). Picks keep tap order — that is the
//    merge order on the next screen. Files the engine cannot read are refused at the tick.
//  - `.single`: plain rows, tapping one picks it — unless it cannot be read or has a single page (Split).
//  No files → "No files found" + Import (no search, no select-all); a search with no match → "No result".
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class HwpFilePickerViewController: AppBaseViewController, ToolFlowScreen {
    enum Mode: Equatable {
        /// `minimum`: picks needed before Continue turns on. Every pick starts unticked, so "Add" on the
        /// Merge screen can pick a file that is already in the merge again (ESI05-55).
        case multiple(minimum: Int)
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
    private let searchHolder = UIView()
    private var bottomBar: UIView?
    private lazy var emptyView = HomeEmptyView(
        image: Asset.Assets.App.imgEmptyNoFiles.image,
        title: L10n.toolsSelectFileEmpty,
        actionTitle: L10n.toolsImportFromFiles
    )
    private lazy var noResultView = HomeEmptyView(
        image: Asset.Assets.App.imgNoResultFoundVector.image,
        title: L10n.searchNoResult
    )
    private lazy var actions = FileActionsCoordinator(presenter: self, viewModel: viewModel)
    /// A file is being opened to check it; further taps wait.
    private var isInspecting = false
    private var items: [FileItem] = []
    /// Picked file ids (`FileItem.id`) in pick order, across searches.
    private var picked: [String] = []
    /// Every picked item seen so far, so a pick hidden by the search query is still returned.
    private var pickedItems: [String: FileItem] = [:]

    private var isMultiple: Bool {
        if case .multiple = mode { return true }
        return false
    }

    private var minimumPicks: Int {
        if case .multiple(let minimum) = mode { return minimum }
        return 1
    }

    init(mode: Mode) {
        self.mode = mode
        let title = mode == .single ? L10n.splitSelectFile : L10n.mergeSelectFiles
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: title))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        MergeSplitUI.addNavHairline(to: navigationView)

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
            bottomBar = MergeSplitUI.bottomBar(in: view, content: continueButton)
            tableView.contentInset.bottom = MergeSplitUI.bottomBarHeight
            continueButton.tapPublisher
                .sink { [weak self] _ in self?.finish() }
                .store(in: &cancellables)
        }

        for state in [emptyView, noResultView] {
            state.isHidden = true
            view.addSubview(state)
            state.snp.makeConstraints { $0.edges.equalTo(tableView) }
        }
        emptyView.onAction = { [weak self] in self?.actions.pickAndImport(family: .hwp) }

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
            tableView.reloadData()
            refreshSelectionUI()
            return
        }
        // Only files the engine can open may join a merge (ESI05-61).
        inspect(item) { [weak self] check in
            guard let self, case .readable = check else { return }
            picked.append(item.id)
            pickedItems[item.id] = item
            tableView.reloadData()
            refreshSelectionUI()
        }
    }

    /// Split: a file that cannot be read or has one page stays here with a toast (ESI05-60 / 64).
    private func pickForSplit(_ item: FileItem) {
        inspect(item) { [weak self] check in
            guard let self, case .readable(let pages) = check else { return }
            guard pages > 1 else { return showToast(L10n.splitOnePage) }
            onPicked?([item])
        }
    }

    /// Opens `item` with the engine (HUD only if it takes a moment) and hands over the verdict; an
    /// unreadable file gets the "invalid file" toast here, an engine that cannot start the offline one.
    private func inspect(_ item: FileItem, then: @escaping (HwpFileCheck) -> Void) {
        guard !isInspecting else { return }
        isInspecting = true
        let hud = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if !Task.isCancelled { self?.showLoadingHUD(true) }
        }
        Task { @MainActor [weak self] in
            let check: HwpFileCheck?
            var failure: Error?
            do { check = try await HwpFileInspector.shared.inspect(item) } catch { check = nil; failure = error }
            hud.cancel()
            guard let self else { return }
            showLoadingHUD(false)
            isInspecting = false
            if let failure { return showToast(ErrorPopup.message(for: failure)) }
            if check == .unreadable { showToast(L10n.viewerInvalidFile) }
            if let check { then(check) }
        }
    }

    /// Select all = every visible (searched) file; when they are all picked, un-pick them. Files the
    /// engine cannot read are left out (they are checked one by one as they are picked).
    private func toggleSelectAll() {
        let visible = items.map(\.id)
        if !visible.isEmpty, visible.allSatisfy(picked.contains) {
            picked.removeAll { visible.contains($0) }
            visible.forEach { pickedItems[$0] = nil }
            tableView.reloadData()
            refreshSelectionUI()
        } else {
            selectAllReadable(items.filter { !picked.contains($0.id) })
        }
    }

    /// Picks `remaining` in order, skipping (and reporting once) the files the engine cannot read.
    private func selectAllReadable(_ remaining: [FileItem]) {
        guard !isInspecting else { return }
        isInspecting = true
        showLoadingHUD(true)
        Task { @MainActor [weak self] in
            var skipped = 0
            var failure: Error?
            for item in remaining {
                do {
                    if case .readable = try await HwpFileInspector.shared.inspect(item) {
                        self?.picked.append(item.id)
                        self?.pickedItems[item.id] = item
                    } else {
                        skipped += 1
                    }
                } catch {
                    failure = error
                    break
                }
            }
            guard let self else { return }
            showLoadingHUD(false)
            isInspecting = false
            tableView.reloadData()
            refreshSelectionUI()
            if let failure { showToast(ErrorPopup.message(for: failure)) } else if skipped > 0 { showToast(L10n.viewerInvalidFile) }
        }
    }

    private func refreshSelectionUI() {
        // No file at all → empty state with Import; a search that matches nothing → "No result".
        let hasNoFiles = items.isEmpty && viewModel.query.isEmpty
        emptyView.isHidden = !hasNoFiles
        noResultView.isHidden = !(items.isEmpty && !viewModel.query.isEmpty)
        searchHolder.isHidden = hasNoFiles
        selectAll.isHidden = items.isEmpty
        bottomBar?.isHidden = hasNoFiles
        guard isMultiple else { return }
        continueButton.setTitle(L10n.mergeContinue(picked.count), for: .normal)
        continueButton.isEnabled = picked.count >= minimumPicks
        selectAll.isOn = !items.isEmpty && items.allSatisfy { picked.contains($0.id) }
    }

    private func finish() {
        let result = picked.compactMap { pickedItems[$0] }
        guard result.count >= minimumPicks else { return }
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
            pickForSplit(item)
        }
    }
}
