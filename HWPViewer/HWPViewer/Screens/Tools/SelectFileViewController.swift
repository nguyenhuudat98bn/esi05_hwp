//
//  SelectFileViewController.swift
//  HWPViewer
//
//  Select File (Figma G2/G6): list of pdf / doc / hwp already in the app, plus "Import from Files".
//  Edit → viewer in edit mode; Print → print; PDF/DOC → rename output (G3) → convert (G4) → result (G5).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class SelectFileViewController: AppBaseViewController {
    private let tool: ToolKind
    private let viewModel: FileListViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let importButton = UIButton(type: .system)
    private lazy var emptyView = HomeEmptyView(
        image: Asset.Assets.App.imgEmptyNoFiles.image,
        title: L10n.toolsSelectFileEmpty,
        actionTitle: L10n.toolsImportFromFiles
    )
    private var items: [FileItem] = []
    private let listAd = ListAdInserter(place: .selectFileListInline)
    private lazy var actions = FileActionsCoordinator(presenter: self, viewModel: viewModel)

    init(tool: ToolKind) {
        self.tool = tool
        self.viewModel = FileListViewModel(filter: .family(tool.family))
        super.init(place: .tools, navigationConfigs: SPNNavigationConfiguration(
            title: L10n.toolsSelectFile, hasBackButton: true,
            titleFont: AppFonts.semibold(18), titleColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }

    private func setupViews() {
        containerStackView.addArrangedSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(FileCell.self, forCellReuseIdentifier: FileCell.identifier)
        tableView.register(NativeAdTableCell.self, forCellReuseIdentifier: NativeAdTableCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        listAd.onChange = { [weak self] in self?.tableView.reloadData() }
        listAd.attachIfNeeded()
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0)

        emptyView.isHidden = true
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalTo(tableView) }

        importButton.setTitle(L10n.toolsImportFromFiles, for: .normal)
        importButton.setImage(Asset.Assets.App.icUpload.image.withRenderingMode(.alwaysTemplate), for: .normal)
        importButton.tintColor = .white
        importButton.setTitleColor(.white, for: .normal)
        importButton.titleLabel?.font = AppFonts.semibold(15)
        importButton.backgroundColor = AppColors.primary
        importButton.layer.cornerRadius = AppMetrics.buttonRadius
        importButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        view.addSubview(importButton)
        importButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(AppMetrics.buttonHeight)
        }
    }

    private func bind() {
        viewModel.$items.receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.items = items
                tableView.reloadData()
                emptyView.isHidden = !items.isEmpty
                importButton.isHidden = items.isEmpty
            }
            .store(in: &cancellables)
        importButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.importFile() }
            .store(in: &cancellables)
        emptyView.onAction = { [weak self] in self?.importFile() }
    }

    private func importFile() {
        actions.pickAndImport(family: tool.family) { [weak self] url in
            guard let self, let item = FileStore.shared.item(at: url) else { return }
            handle(item)
        }
    }

    private func handle(_ item: FileItem) {
        switch tool {
        case .editHwp:
            if AppRemoteConfigs.current.isEditPremium {
                requirePremium { [weak self] in self?.actions.open(item, startInEditMode: true) }
            } else {
                actions.open(item, startInEditMode: true)
            }
        case .print:
            actions.print(item)
        case .pdfToHwp, .docToHwp:
            startConvert(item)
        }
    }

    // G3: output name → G4 convert → G5 result
    private func startConvert(_ item: FileItem) {
        let dialog = RenameDialog(title: L10n.convertTitle, initialName: item.displayName, confirmTitle: L10n.popupOk)
        dialog.validator = { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.rangeOfCharacter(from: FileStore.invalidNameCharacters) != nil { return L10n.renameErrorInvalid }
            if FileStore.shared.fileExists(named: "\(trimmed).hwp") { return L10n.renameErrorExists }
            return nil
        }
        dialog.onConfirm = { [weak self] name in
            guard let self else { return }
            let run = { [weak self] in
                guard let self else { return }
                let converting = ConvertingViewController(source: item, outputName: name)
                navigationController?.pushViewController(converting, animated: true)
            }
            if AppRemoteConfigs.current.isConvertPremium {
                requirePremium(run)
            } else {
                run()
            }
        }
        present(dialog, animated: true)
    }
}

extension SelectFileViewController: UITableViewDataSource, UITableViewDelegate {
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
        cell.configure(items[index], showsBookmark: false, showsMore: false)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        listAd.isAdRow(indexPath.row, itemCount: items.count) ? listAd.adRowHeight : AppMetrics.cellHeight + AppMetrics.cellSpacing
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let index = listAd.itemIndex(for: indexPath.row, itemCount: items.count) else { return }
        handle(items[index])
    }
}
