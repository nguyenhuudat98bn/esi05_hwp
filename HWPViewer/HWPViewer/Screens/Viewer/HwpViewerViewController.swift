//
//  HwpViewerViewController.swift
//  HWPViewer
//
//  View mode (Figma F1): back / search / ⋯, vertical pages, "1/2" badge, full-width "Edit HWP".
//  Edit mode (F2–F8): X / Save header, format toolbar above keyboard, selection menu, Save Changes popup.
//  Rendering / editing comes from HwpEditorKit (EditorViewModel + DocumentCanvasCoordinator).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import HwpEditorKit
import SPNComponent

final class HwpViewerViewController: AppBaseViewController {
    // MARK: - Engine
    private let vm = EditorViewModel()
    private let coordinator = DocumentCanvasCoordinator()
    private let scrollView = DocumentScrollView()
    private let keyCatcher = KeyCatcherView()

    // MARK: - Controls
    private let formatToolbar = HwpFormatToolbar()
    private let editHeader = HwpEditHeaderView()
    private let searchBarView = HwpSearchBar()
    private let bottomBar = UIView()
    private let editButton = UIButton(type: .system)
    private let pageIndicator: PaddingLabel = {
        let label = PaddingLabel()
        label.topInset = 4
        label.bottomInset = 4
        label.leftInset = 16
        label.rightInset = 16
        return label
    }()
    private lazy var fontLoadingView: UIView = {
        let container = UIView()
        container.backgroundColor = AppColors.surface
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppColors.primary
        spinner.startAnimating()
        let label = UILabel()
        label.text = L10n.viewerLoadingFonts
        label.font = AppFonts.regular(14)
        label.textColor = AppColors.textSecondary
        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        container.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        return container
    }()

    // MARK: - State
    private var item: FileItem
    private var startInEditMode: Bool
    private var searchMatches: [HwpSearchMatch] = []
    private var searchIndex = 0
    private var searchQueryToken = 0
    private var lastMode: EditorViewModel.EditorMode = .read
    private var syncScheduled = false
    private var didShowSelectionHint = false
    private var isSearching = false
    private var pendingColorTarget: HwpFormatToolbar.ColorTarget?
    /// Colour of the text when the current selection was made. The engine has no "clear colour"
    /// operation (a cleared run renders white), so the default swatch re-applies this instead.
    private var selectionOriginalTextColor: String?
    private var hadSelection = false
    private lazy var actions = FileActionsCoordinator(presenter: self, viewModel: FileListViewModel(filter: .all))

    private enum NavItem {
        static let search = "search"
        static let more = "more"
    }

    // MARK: - Init
    init(item: FileItem, startInEditMode: Bool = false) {
        self.item = item
        self.startInEditMode = startInEditMode
        super.init(place: .viewer, navigationConfigs: SPNNavigationConfiguration(
            title: "",
            hasBackButton: true,
            backIcon: Asset.Assets.App.icAngleLeft.image,
            rightItems: [
                SPNNavigationItem(id: NavItem.search, icon: Asset.Assets.App.icSearch.image),
                SPNNavigationItem(id: NavItem.more, icon: Asset.Assets.App.icViewerMoreVertical.image),
            ],
            tintColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
        bindActions()
        setupAdvertiser(on: .viewer)
        loadDocument()
    }

    override func backButtonTapped() {
        if vm.mode == .edit {
            closeEditTapped()
            return
        }
        super.backButtonTapped()
    }

    // MARK: - Load
    private func loadDocument() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if !HwpFontManager.shared.isReady { showFontLoading(true) }
            do {
                try await HwpEngine.prepare()
            } catch {
                showFontLoading(false)
                OfflinePopup.present(from: self) { [weak self] in self?.loadDocument() }
                return
            }
            showFontLoading(false)
            showLoadingHUD(true)
            coordinator.onFirstRender = { [weak self] in self?.showLoadingHUD(false) }
            await vm.openAsync(url: item.url)
            if vm.document == nil {
                showLoadingHUD(false)
                // The engine says *why* it could not parse (unknown container, encrypted, bad XML).
                // Throwing that away left every failure looking like "HWPX is not supported"
                // (ESI05-25) with nothing to diagnose from.
                logger("[HWP] open failed for \(item.url.lastPathComponent): \(vm.errorMessage ?? "unknown")")
                vm.errorMessage = nil
                showOpenError()
                return
            }
            if vm.pages.isEmpty { showLoadingHUD(false) }
            // Khôi phục trang đọc lần trước (coordinator tự chờ layout xong rồi cuộn).
            if let page = FileStore.shared.lastPage(for: item.url), page > 0, page < vm.pages.count {
                coordinator.scrollToPage(page)
            }
            if startInEditMode {
                startInEditMode = false
                enterEditMode()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in self?.showLoadingHUD(false) }
        }
    }

    /// Figma 19108-24632: a broken file gets the same full error screen as a failed convert.
    /// It replaces this controller in the stack so backing out of it cannot return to a viewer
    /// that has no document.
    private func showOpenError() {
        guard let nav = navigationController else { return }
        var stack = nav.viewControllers
        stack.removeAll { $0 === self }
        stack.append(DocumentErrorViewController(place: .viewer))
        nav.setViewControllers(stack, animated: true)
    }

    private func showFontLoading(_ show: Bool) {
        if show {
            guard fontLoadingView.superview == nil else { return }
            view.addSubview(fontLoadingView)
            fontLoadingView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        } else {
            fontLoadingView.removeFromSuperview()
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = AppColors.viewerBackground
        navigationView.snp.updateConstraints { $0.height.equalTo(AppMetrics.navHeight) }
        let navLine = UIView()
        navLine.backgroundColor = AppColors.divider
        navigationView.addSubview(navLine)
        navLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        containerStackView.spacing = 0
        formatToolbar.isHidden = true
        containerStackView.addArrangedSubview(formatToolbar)
        containerStackView.addArrangedSubview(scrollView)
        containerStackView.addArrangedSubview(nativeAdSlot)
        containerStackView.addArrangedSubview(bottomBar)
        coordinator.attach(scrollView: scrollView, vm: vm)
        scrollView.backgroundColor = AppColors.viewerBackground

        // Bottom bar: "Edit HWP" (read mode only). Note: never un-hide `nativeAdSlot` by hand —
        // an empty slot takes ~170pt and shrinks the document area.
        bottomBar.backgroundColor = AppColors.surface
        let topLine = UIView()
        topLine.backgroundColor = AppColors.surfaceCircle
        bottomBar.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(1)
        }
        editButton.setTitle(L10n.viewerEditHwp, for: .normal)
        editButton.titleLabel?.font = AppFonts.semibold(16)
        editButton.setTitleColor(.white, for: .normal)
        editButton.backgroundColor = AppColors.primary
        editButton.layer.cornerRadius = AppMetrics.buttonRadius
        bottomBar.addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(AppMetrics.buttonHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        view.addSubview(keyCatcher)
        keyCatcher.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(0)
        }

        pageIndicator.backgroundColor = AppColors.pageBadge
        pageIndicator.textColor = .white
        pageIndicator.font = AppFonts.medium(14)
        pageIndicator.textAlignment = .center
        pageIndicator.layer.cornerRadius = 4
        pageIndicator.clipsToBounds = true
        pageIndicator.isHidden = true
        view.addSubview(pageIndicator)
        pageIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top).offset(-26)
        }

        // Edit chrome (toolbar sits under the header, Figma F2)
        formatToolbar.snp.makeConstraints { $0.height.equalTo(56) }

        editHeader.isHidden = true
        view.addSubview(editHeader)
        editHeader.snp.makeConstraints { $0.edges.equalTo(navigationView) }

        searchBarView.isHidden = true
        searchBarView.alpha = 0
        view.addSubview(searchBarView)
        searchBarView.snp.makeConstraints { $0.edges.equalTo(navigationView) }
    }

    // MARK: - Bindings
    private func bindViewModel() {
        vm.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, !syncScheduled else { return }
                syncScheduled = true
                DispatchQueue.main.async {
                    self.syncScheduled = false
                    self.syncFromViewModel()
                }
            }
            .store(in: &cancellables)

        keyCatcher.onInsert = { [weak self] text in self?.vm.typeText(text) }
        keyCatcher.onDeleteBackward = { [weak self] in self?.vm.deleteBackward() }
        keyCatcher.onDismiss = { [weak self] in self?.vm.endEditing() }

        scrollView.publisher(for: \.contentOffset)
            .receive(on: DispatchQueue.main)
            .throttle(for: .milliseconds(120), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in self?.updatePageIndicator() }
            .store(in: &cancellables)
    }

    private func bindActions() {
        navigationView.itemTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let self else { return }
                switch item.id {
                case NavItem.search:
                    toggleSearchBar(isShow: true)
                case NavItem.more:
                    moreTapped()
                default: break
                }
            }
            .store(in: &cancellables)

        searchBarView.onQueryChanged = { [weak self] query in self?.performSearch(query) }
        searchBarView.onPrev = { [weak self] in self?.stepSearch(-1) }
        searchBarView.onNext = { [weak self] in self?.stepSearch(1) }
        searchBarView.onCancel = { [weak self] in
            self?.clearSearch()
            self?.toggleSearchBar(isShow: false)
        }

        editButton.tapPublisher
            .throttle(for: .seconds(0.35), scheduler: RunLoop.main, latest: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.editTapped() }
            .store(in: &cancellables)

        editHeader.onClose = { [weak self] in self?.closeEditTapped() }
        editHeader.onSave = { [weak self] in self?.saveTapped() }

        formatToolbar.onAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .undo: vm.undo()
            case .redo: vm.redo()
            case .bold: vm.applyFormat(RhwpCharFormat(bold: !(vm.charProps?.bold ?? false)))
            case .italic: vm.applyFormat(RhwpCharFormat(italic: !(vm.charProps?.italic ?? false)))
            case .underline: vm.applyFormat(RhwpCharFormat(underline: !(vm.charProps?.underline ?? false)))
            case .strikethrough: vm.applyFormat(RhwpCharFormat(strikethrough: !(vm.charProps?.strikethrough ?? false)))
            case .alignLeft: vm.applyAlignment(.left)
            case .alignRight: vm.applyAlignment(.right)
            case .highlight(let hex): vm.applyFormat(RhwpCharFormat(highlightColor: hex ?? HwpFormatToolbar.clearHighlight))
            case .textColor(let hex):
                vm.applyFormat(RhwpCharFormat(textColor: hex ?? selectionOriginalTextColor ?? "#000000"))
            case .fontSize(let pt): vm.applyFormat(RhwpCharFormat(fontSizePt: pt))
            case .pickColor(let target): presentColorPicker(for: target)
            case .selectionHint: showToast(L10n.viewerSelectionRequired)
            }
        }
    }

    // MARK: - Edit mode
    private func editTapped() {
        let run: () -> Void = { [weak self] in self?.enterEditMode() }
        if AppRemoteConfigs.current.isEditPremium {
            requirePremium(run)
        } else {
            run()
        }
    }

    private func enterEditMode() {
        clearSearch()
        toggleSearchBar(isShow: false)
        vm.enterEditMode()
        if !didShowSelectionHint {
            didShowSelectionHint = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.showToast(L10n.viewerSelectionHint)
            }
        }
    }

    private func closeEditTapped() {
        guard vm.canUndo else {
            vm.exitEditMode()
            return
        }
        let wasEditing = vm.isEditing
        SaveChangesPopup.present(from: self, cancel: { [weak self] in
            guard let self else { return }
            vm.discardAllChanges()
            vm.exitEditMode()
            _ = wasEditing
        }, save: { [weak self] in
            self?.commitSave()
        })
    }

    /// Header "Save": confirm with the Save Changes popup (Figma 18387:126424) before writing the file.
    private func saveTapped() {
        guard vm.canUndo else {
            vm.exitEditMode()
            return
        }
        SaveChangesPopup.present(from: self, cancel: {}, save: { [weak self] in
            self?.commitSave()
        })
    }

    private func commitSave() {
        vm.endEditing()
        performSave()
    }

    private func performSave() {
        guard let doc = vm.document else { return }
        let url = item.url
        showLoadingHUD(true)
        view.isUserInteractionEnabled = false
        Task { @MainActor [weak self] in
            await self?.vm.waitForPendingEdits()
            let result: Result<Void, Error> = await Task.detached(priority: .userInitiated) {
                do {
                    _ = try doc.save(to: url)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }.value
            guard let self else { return }
            showLoadingHUD(false)
            view.isUserInteractionEnabled = true
            switch result {
            case .success:
                vm.markSaved()
                vm.exitEditMode()
                FileStore.shared.notifyChanged()
                // No "Saved" toast: the confirm popup + leaving edit mode is feedback enough.
            case .failure(let error):
                logger("[HWP] save failed: \(error)")
                ErrorPopup.present(from: self, message: L10n.viewerSaveFailed)
            }
        }
    }

    private func presentColorPicker(for target: HwpFormatToolbar.ColorTarget) {
        pendingColorTarget = target
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = self
        if let hex = target == .text ? vm.charProps?.textColor : vm.charProps?.shadeColor {
            picker.selectedColor = UIColor(hex: hex)
        }
        present(picker, animated: true)
    }

    // MARK: - Sync
    private func syncFromViewModel() {
        coordinator.sync(vm: vm)
        captureOriginalTextColorIfNeeded()
        keyCatcher.setActive(vm.isEditing && vm.mode == .edit)
        formatToolbar.update(
            charProps: vm.charProps,
            alignment: currentParagraphAlignment(),
            hasSelection: vm.hasSelection,
            canAlign: vm.caret != nil && !(vm.caret?.position.isInCell ?? false),
            canUndo: vm.canUndo,
            canRedo: vm.canRedo,
            isApplying: vm.isApplyingEdit
        )
        editHeader.setSaveEnabled(vm.canUndo)
        formatToolbar.isUserInteractionEnabled = !vm.isApplyingEdit
        editHeader.isUserInteractionEnabled = !vm.isApplyingEdit
        if vm.mode != lastMode {
            lastMode = vm.mode
            updateChrome()
        }
        if let message = vm.errorMessage {
            vm.errorMessage = nil
            ErrorPopup.present(from: self, message: message)
        }
        updatePageIndicator()
    }

    /// Alignment of the paragraph holding the caret, so the toolbar can light the matching button.
    /// Read on demand — the view model does not publish paragraph properties.
    private func currentParagraphAlignment() -> RhwpAlignment? {
        guard vm.mode == .edit, let doc = vm.document,
              let position = vm.caret?.position, !position.isInCell else { return nil }
        return try? doc.paraProperties(section: position.sectionIndex, paragraph: position.paragraphIndex).align
    }

    /// Snapshots the text colour the moment a selection appears; cleared when it goes away.
    private func captureOriginalTextColorIfNeeded() {
        if vm.hasSelection, !hadSelection {
            selectionOriginalTextColor = vm.charProps?.textColor
        } else if !vm.hasSelection {
            selectionOriginalTextColor = nil
        }
        hadSelection = vm.hasSelection
    }

    private func updateChrome() {
        let isEdit = vm.mode == .edit
        editHeader.isHidden = !isEdit
        formatToolbar.isHidden = !isEdit
        bottomBar.isHidden = isEdit || isSearching
        pageIndicator.isHidden = isEdit || vm.pages.isEmpty
        if !isEdit { formatToolbar.collapseStrips() }
    }

    private func updatePageIndicator() {
        let total = vm.pages.count
        guard total > 0, vm.mode == .read else {
            pageIndicator.isHidden = true
            return
        }
        let current = (coordinator.currentVisiblePage() ?? 0) + 1
        pageIndicator.isHidden = false
        pageIndicator.text = "\(current)/\(total)"
        // Lưu vị trí đọc (throttle theo scroll đã có ở publisher contentOffset).
        FileStore.shared.setLastPage(current - 1, for: item.url)
    }

    // MARK: - Search
    private func toggleSearchBar(isShow: Bool) {
        if searchBarView.isHidden == !isShow { return }
        // Figma F1: searching replaces the whole read chrome — no "Edit HWP" CTA while it is open.
        isSearching = isShow
        updateChrome()
        if isShow { searchBarView.isHidden = false }
        UIView.animate(withDuration: 0.25, animations: {
            self.searchBarView.alpha = isShow ? 1 : 0
        }, completion: { _ in
            if isShow {
                // Take focus only once the bar is fully in place: claiming it mid-animation let a
                // still-dismissing sheet (the More popup) resign it again and the keyboard
                // flashed away (ESI05-27).
                self.searchBarView.showKeyboard()
            } else {
                self.searchBarView.isHidden = true
            }
        })
    }

    private func performSearch(_ query: String) {
        searchQueryToken += 1
        let token = searchQueryToken
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearSearch()
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let matches = await vm.searchMatches(for: query)
            guard token == searchQueryToken else { return }
            searchMatches = matches
            searchIndex = 0
            searchBarView.setResultCount(matches.count)
            if matches.isEmpty {
                vm.clearSearchHighlight()
            } else {
                showCurrentMatch()
            }
        }
    }

    private func stepSearch(_ delta: Int) {
        guard !searchMatches.isEmpty else { return }
        searchIndex = (searchIndex + delta + searchMatches.count) % searchMatches.count
        showCurrentMatch()
    }

    private func showCurrentMatch() {
        guard searchMatches.indices.contains(searchIndex) else { return }
        if let rect = vm.highlightSearchMatch(searchMatches[searchIndex]) {
            coordinator.scrollTo(matchRect: rect)
        }
    }

    private func clearSearch() {
        searchMatches = []
        searchIndex = 0
        searchBarView.reset()
        vm.clearSearchHighlight()
    }

    // MARK: - More
    private func moreTapped() {
        guard let fresh = FileStore.shared.item(at: item.url) else { return }
        item = fresh
        let sheet = FileActionSheet(item: fresh, actions: [.rename, .share, .print, .delete])
        sheet.onBookmark = { [weak self] in
            guard let self else { return }
            FileStore.shared.toggleBookmark(item.url)
        }
        sheet.onAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .rename:
                actions.rename(fresh) { [weak self] url in
                    guard let self, let renamed = FileStore.shared.item(at: url) else { return }
                    item = renamed
                }
            case .share: ShareService.share(item.url, from: self)
            case .print: PrintService.printHwp(item, from: self)
            case .delete:
                actions.delete(fresh) { [weak self] in self?.navigationController?.popViewController(animated: true) }
            case .edit: editTapped()
            }
        }
        present(sheet, animated: true)
    }
}

// MARK: - Toast placement

extension HwpViewerViewController: ToastInsetProviding {
    /// The toast is blue like the "Edit HWP" pill, so it has to sit above the bar, not on it.
    var toastBottomInset: CGFloat {
        guard !bottomBar.isHidden else { return 24 }
        // Clear the page badge too — it floats 26pt above the bar and is 25pt tall.
        return bottomBar.bounds.height + (pageIndicator.isHidden ? 12 : 59)
    }
}

// MARK: - Color picker

extension HwpViewerViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        applyPicked(viewController.selectedColor)
        pendingColorTarget = nil
    }

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        if !continuously { applyPicked(color) }
    }

    private func applyPicked(_ color: UIColor) {
        guard let target = pendingColorTarget else { return }
        let hex = color.hexString
        switch target {
        case .text: vm.applyFormat(RhwpCharFormat(textColor: hex))
        case .highlight: vm.applyFormat(RhwpCharFormat(highlightColor: hex))
        }
    }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}
