//
//  MergeOrderViewController.swift
//  HWPViewer
//
//  Merge 2 (design "Merge 2 – Order & name"): drag to reorder, remove, "Add files" (back to Merge 1),
//  output name + HWP/HWPX, then Merge → progress popup → result.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class MergeOrderViewController: AppBaseViewController {
    /// Called whenever the list changes, so Merge 1 can mirror it.
    var onFilesChanged: (([FileItem]) -> Void)?

    private var files: [FileItem]
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let nameField = UITextField()
    private let formatControl = MergeSplitUI.segmented(["HWP", "HWPX"])
    private let mergeButton = MergeSplitUI.pillButton("")

    init(files: [FileItem]) {
        self.files = files
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: L10n.mergeTitle))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        containerStackView.addArrangedSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 70
        tableView.register(SelectableFileCell.self, forCellReuseIdentifier: SelectableFileCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true   // system reorder grabbers
        tableView.tableHeaderView = makeHeader()
        tableView.tableFooterView = makeFooter()
        tableView.contentInset.bottom = 100

        _ = MergeSplitUI.bottomBar(in: view, content: mergeButton)
        mergeButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.startMerge() }
            .store(in: &cancellables)
        nameField.text = "Merged_\(files.first?.displayName ?? "HWP")"
        refresh()
    }

    private func refresh() {
        tableView.reloadData()
        mergeButton.setTitle(L10n.mergeAction(files.count), for: .normal)
        mergeButton.isEnabled = files.count >= 2
        mergeButton.alpha = mergeButton.isEnabled ? 1 : 0.5
        onFilesChanged?(files)
    }

    private func makeHeader() -> UIView {
        let title = MergeSplitUI.label(L10n.mergeOrder, font: AppFonts.semibold(16))
        let hint = MergeSplitUI.label(L10n.mergeDragHint, font: AppFonts.regular(12), color: UIColor(hex: "#535862"))
        let row = UIStackView(arrangedSubviews: [title, hint])
        row.alignment = .lastBaseline
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        header.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 6, right: 16)) }
        return header
    }

    private func makeFooter() -> UIView {
        let add = MergeSplitUI.dashedAddButton(L10n.mergeAddFiles)
        add.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.navigationController?.popViewController(animated: true) }
            .store(in: &cancellables)

        let output = MergeSplitUI.label(L10n.mergeOutput, font: AppFonts.semibold(16))
        let nameTitle = MergeSplitUI.label(L10n.mergeFileName, font: AppFonts.regular(13), color: UIColor(hex: "#535862"))
        nameField.font = AppFonts.regular(16)
        nameField.textColor = AppColors.textPrimary
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .done
        nameField.addTarget(nameField, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)
        let nameBox = UIView()
        nameBox.layer.cornerRadius = 12
        nameBox.layer.borderWidth = 1
        nameBox.layer.borderColor = AppColors.border.cgColor
        nameBox.addSubview(nameField)
        nameField.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 10)) }
        nameBox.snp.makeConstraints { $0.height.equalTo(48) }
        let note = MergeSplitUI.label(L10n.mergeNewPageNote, font: AppFonts.regular(13), color: UIColor(hex: "#535862"), lines: 0)

        let stack = UIStackView(arrangedSubviews: [add, output, nameTitle, nameBox, formatControl, note])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(24, after: add)
        stack.setCustomSpacing(12, after: output)
        stack.setCustomSpacing(6, after: nameTitle)
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 330))
        footer.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
        return footer
    }

    private func startMerge() {
        view.endEditing(true)
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let asHWPX = formatControl.selectedSegmentIndex == 1
        guard !name.isEmpty, name.rangeOfCharacter(from: FileStore.invalidNameCharacters) == nil else {
            showToast(L10n.renameErrorInvalid); return
        }
        guard !FileStore.shared.fileExists(named: "\(name).\(asHWPX ? "hwpx" : "hwp")") else {
            showToast(L10n.renameErrorExists); return
        }
        let files = self.files
        let popup = TaskProgressPopupViewController<DocumentOutput>(title: L10n.mergeProgress, symbol: "doc.on.doc") { report in
            try await HwpMergeSplitService.shared.merge(files, outputName: name, asHWPX: asHWPX) { fraction, file in
                let index = (files.firstIndex { $0.id == file.id } ?? 0) + 1
                report(fraction, L10n.mergeProgressStep(file.name, index, files.count))
            }
        }
        popup.onFinished = { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let output):
                let done = MergeSplitResultViewController(
                    title: L10n.mergeDone, subtitle: L10n.mergeDoneSubtitle(files.count), outputs: [output])
                navigationController?.pushViewController(done, animated: true)
            case .failure(let error):
                logger("[Merge] failed: \(error)")
                ErrorPopup.present(from: self, message: error.localizedDescription)
            }
        }
        present(popup, animated: true)
    }
}

extension MergeOrderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { files.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectableFileCell.identifier, for: indexPath) as! SelectableFileCell
        let item = files[indexPath.row]
        cell.configure(name: item.name, meta: item.sizeText, kind: item.kind, order: indexPath.row + 1)
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        let item = files.remove(at: source.row)
        files.insert(item, at: destination.row)
        DispatchQueue.main.async { [weak self] in self?.refresh() }   // renumber badges after the drop
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .delete }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        files.remove(at: indexPath.row)
        refresh()
    }
}
