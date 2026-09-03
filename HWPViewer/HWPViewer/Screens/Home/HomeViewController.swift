//
//  HomeViewController.swift
//  HWPViewer
//
//  Home (Figma B1/B2/B6/B7): header, feature cards, My File / Recent / Bookmark, FAB import.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import UniformTypeIdentifiers
import SPNComponent

final class HomeViewController: AppBaseViewController {
    // MARK: - Controls
    private let headerView = HomeHeaderView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let tabs = SegmentTabsView(titles: [L10n.homeTabMyFile, L10n.homeTabRecent, L10n.homeTabBookmark])
    private lazy var emptyView = HomeEmptyView(
        image: Asset.Assets.App.imgEmptyNoFiles.image,
        title: L10n.homeEmptyTitle,
        actionTitle: L10n.homeEmptyImport,
        actionIcon: Asset.Assets.App.icUpload.image
    )
    private let fab = UIButton(type: .system)
    private let cardsView = UIView()
    private let editCard = GradientCardView(tool: .editHwp)
    private let pdfCard = GradientCardView(tool: .pdfToHwp)

    // MARK: - State
    private let viewModel = FileListViewModel(filter: .all)
    private var items: [FileItem] = []
    private let listAd = ListAdInserter(place: .homeListInline)
    private lazy var actions = FileActionsCoordinator(presenter: self, viewModel: viewModel)

    // MARK: - Init
    init() {
        super.init(place: .home, navigationConfigs: SPNNavigationConfiguration(title: "", hasBackButton: false, backgroundColor: AppColors.background))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var hidesBottomBarByDefault: Bool { false }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.isHidden = true
        setupViews()
        bind()
        listAd.onChange = { [weak self] in self?.tableView.reloadData() }
        listAd.attachIfNeeded()
        SPNSession.shared.isFirstTimeOnboard = false
        HwpFontManager.shared.prefetchIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IncomingFileHandler.shared.tryOpen()
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = AppColors.background
        containerStackView.spacing = 0
        containerStackView.addArrangedSubview(headerView)
        headerView.snp.makeConstraints { $0.height.equalTo(52) }
        containerStackView.addArrangedSubview(tableView)
        containerStackView.addArrangedSubview(nativeAdSlot)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(FileCell.self, forCellReuseIdentifier: FileCell.identifier)
        tableView.register(NativeAdTableCell.self, forCellReuseIdentifier: NativeAdTableCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        tableView.showsVerticalScrollIndicator = false

        // Header (cards + tabs) scrolls with the list.
        let header = UIView()
        header.addSubview(cardsView)
        header.addSubview(tabs)
        cardsView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.height.equalTo(88)
        }
        let cardStack = UIStackView(arrangedSubviews: [editCard, pdfCard])
        cardStack.axis = .horizontal
        cardStack.spacing = 12
        cardStack.distribution = .fillEqually
        cardsView.addSubview(cardStack)
        cardStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        tabs.snp.makeConstraints { make in
            make.top.equalTo(cardsView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.height.equalTo(26)
            make.bottom.equalToSuperview().inset(12)
        }
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 8 + 88 + 16 + 26 + 12)
        tableView.tableHeaderView = header

        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(tableView)
            make.top.equalTo(tableView).offset(header.frame.height)
            make.bottom.equalTo(tableView)
        }

        fab.setImage(Asset.Assets.App.icRoundPlus.image.withRenderingMode(.alwaysTemplate), for: .normal)
        fab.tintColor = .white
        fab.backgroundColor = AppColors.primary
        fab.layer.cornerRadius = 24
        fab.layer.shadowColor = AppColors.primary.cgColor
        fab.layer.shadowOpacity = 0.35
        fab.layer.shadowRadius = 10
        fab.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.addSubview(fab)
        fab.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(tableView.snp.bottom).inset(24)
        }
    }

    private func bind() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.items = items
                tableView.reloadData()
                updateEmptyState()
            }
            .store(in: &cancellables)

        tabs.onSelect = { [weak self] index in
            guard let self else { return }
            switch index {
            case 1: viewModel.filter = .recent
            case 2: viewModel.filter = .bookmark
            default: viewModel.filter = .all
            }
        }

        headerView.onSearch = { [weak self] in
            self?.navigationController?.pushViewController(SearchViewController(), animated: true)
        }
        headerView.onPremium = { [weak self] in self?.presentPaywall() }

        fab.tapPublisher.throttle(for: .seconds(0.4), scheduler: RunLoop.main, latest: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.presentImportSheet() }
            .store(in: &cancellables)
        emptyView.onAction = { [weak self] in self?.presentImportSheet() }

        editCard.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.openTool(.editHwp) }
            .store(in: &cancellables)
        pdfCard.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.openTool(.pdfToHwp) }
            .store(in: &cancellables)
    }

    /// Empty list → native at the bottom; list with files → inline row instead (never both).
    private var bottomAdAttached = false

    private func updateBottomAd(isEmpty: Bool) {
        if isEmpty {
            guard !bottomAdAttached else { return }
            bottomAdAttached = true
            nativeAdSlot.attach(place: .home, style: .native)
        } else if bottomAdAttached {
            bottomAdAttached = false
            nativeAdSlot.detach()
        }
    }

    private func updateEmptyState() {
        let isEmpty = items.isEmpty
        emptyView.isHidden = !isEmpty
        updateBottomAd(isEmpty: isEmpty)
        // Figma B2: no segment tabs / FAB when the library itself is empty.
        let libraryEmpty = isEmpty && viewModel.filter == .all
        tabs.isHidden = libraryEmpty
        fab.isHidden = libraryEmpty
        switch viewModel.filter {
        case .recent: emptyView.update(title: L10n.homeEmptyRecent, subtitle: nil, actionTitle: nil)
        case .bookmark: emptyView.update(title: L10n.homeEmptyBookmark, subtitle: nil, actionTitle: nil)
        default: emptyView.update(title: L10n.homeEmptyTitle, subtitle: nil, actionTitle: L10n.homeEmptyImport)
        }
    }

    override func premiumStatusDidChange() {
        super.premiumStatusDidChange()
        headerView.setPremiumHidden(isPremium)
        if isPremium { listAd.detach() }
    }

    // MARK: - Navigation
    private func presentImportSheet() {
        let sheet = ImportSheetViewController()
        sheet.onImportHwp = { [weak self] in self?.actions.pickAndImport(family: .hwp) }
        sheet.onConvert = { [weak self] tool in self?.openTool(tool) }
        present(sheet, animated: true)
    }

    private func openTool(_ tool: ToolKind) {
        let vc = SelectFileViewController(tool: tool)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func open(_ item: FileItem) {
        actions.open(item)
    }
}

// MARK: - UITableView

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listAd.rowCount(itemCount: items.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let index = listAd.itemIndex(for: indexPath.row, itemCount: items.count) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NativeAdTableCell.identifier, for: indexPath) as! NativeAdTableCell
            cell.host(listAd.slot)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: FileCell.identifier, for: indexPath) as! FileCell
        let item = items[index]
        cell.configure(item)
        cell.onBookmark = { [weak self] in self?.actions.toggleBookmark(item) }
        cell.onMore = { [weak self] in self?.actions.presentMore(for: item) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        listAd.isAdRow(indexPath.row, itemCount: items.count) ? listAd.adRowHeight : AppMetrics.cellHeight + AppMetrics.cellSpacing
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let index = listAd.itemIndex(for: indexPath.row, itemCount: items.count) else { return }
        open(items[index])
    }

    #if DEBUG
    /// Smoke-test hooks (SPN_DEBUG_SCREEN=import|more|rename).
    func debugPresent(_ what: String) {
        switch what {
        case "import": presentImportSheet()
        case "more": if let first = items.first { actions.presentMore(for: first) }
        case "rename": if let first = items.first { actions.rename(first) }
        case "delete": if let first = items.first { DeleteConfirmPopup.present(from: self, fileName: first.name) {} }
        case "offline": OfflinePopup.present(from: self) {}
        default: break
        }
    }
    #endif
}

// MARK: - Header

final class HomeHeaderView: UIView {
    var onSearch: (() -> Void)?
    var onPremium: (() -> Void)?

    private let titleLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    private let premiumButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let title = NSMutableAttributedString(string: L10n.homeHeaderHwp, attributes: [.foregroundColor: AppColors.primary, .font: AppFonts.bold(22)])
        title.append(NSAttributedString(string: L10n.homeHeaderEditor, attributes: [.foregroundColor: AppColors.textPrimary, .font: AppFonts.bold(22)]))
        titleLabel.attributedText = title

        searchButton.setImage(Asset.Assets.App.icSearch.image.withRenderingMode(.alwaysTemplate), for: .normal)
        searchButton.tintColor = AppColors.textPrimary
        premiumButton.setImage(Asset.Assets.App.icCrown.image.withRenderingMode(.alwaysOriginal), for: .normal)

        addSubview(titleLabel)
        addSubview(searchButton)
        addSubview(premiumButton)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppMetrics.screenPadding)
            make.centerY.equalToSuperview()
        }
        premiumButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        searchButton.snp.makeConstraints { make in
            make.trailing.equalTo(premiumButton.snp.leading)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        searchButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onSearch?() }.store(in: &cancellables)
        premiumButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onPremium?() }.store(in: &cancellables)
        setPremiumHidden(SPNSession.shared.isPremium)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setPremiumHidden(_ hidden: Bool) {
        premiumButton.isHidden = hidden
        searchButton.snp.updateConstraints { make in
            make.trailing.equalTo(premiumButton.snp.leading).offset(hidden ? 40 : 0)
        }
    }
}
