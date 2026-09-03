//
//  SearchViewController.swift
//  HWPViewer
//
//  Search (Figma C1–C3): back + search field focused on entry, results reuse FileCell, "No result" state.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class SearchViewController: AppBaseViewController {
    private let searchField = UITextField()
    private let fieldContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private lazy var emptyView = HomeEmptyView(
        image: Asset.Assets.App.imgNoResultFound.image,
        title: L10n.searchNoResult
    )
    private let viewModel = FileListViewModel(filter: .all)
    private var items: [FileItem] = []
    private lazy var actions = FileActionsCoordinator(presenter: self, viewModel: viewModel)

    init() {
        super.init(place: .search, navigationConfigs: SPNNavigationConfiguration(title: "", hasBackButton: true, backgroundColor: AppColors.background))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.requiresQuery = true
        setupViews()
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchField.becomeFirstResponder()
    }

    private func setupViews() {
        navigationView.snp.updateConstraints { $0.height.equalTo(AppMetrics.navHeight) }
        // Search field sits inside the nav bar, right of the back button.
        fieldContainer.backgroundColor = AppColors.surfaceMuted
        fieldContainer.layer.cornerRadius = 20
        let icon = UIImageView(image: Asset.Assets.App.icSearch.image.withRenderingMode(.alwaysTemplate))
        icon.tintColor = AppColors.textTertiary
        icon.contentMode = .scaleAspectFit
        searchField.placeholder = L10n.searchPlaceholder
        searchField.font = AppFonts.regular(15)
        searchField.textColor = AppColors.textPrimary
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.autocorrectionType = .no
        fieldContainer.addSubview(icon)
        fieldContainer.addSubview(searchField)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        searchField.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        navigationView.addSubview(fieldContainer)
        fieldContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(56)
            make.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        containerStackView.addArrangedSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(FileCell.self, forCellReuseIdentifier: FileCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = AppMetrics.cellHeight + 16
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)

        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalTo(tableView) }
    }

    private func bind() {
        searchField.textPublisher
            .map { $0 ?? "" }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.viewModel.query = $0 }
            .store(in: &cancellables)

        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.items = items
                tableView.reloadData()
                let query = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
                emptyView.isHidden = !(items.isEmpty && !query.isEmpty)
            }
            .store(in: &cancellables)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileCell.identifier, for: indexPath) as! FileCell
        let item = items[indexPath.row]
        cell.configure(item)
        cell.onBookmark = { [weak self] in self?.actions.toggleBookmark(item) }
        cell.onMore = { [weak self] in self?.actions.presentMore(for: item) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchField.resignFirstResponder()
        actions.open(items[indexPath.row])
    }
}
