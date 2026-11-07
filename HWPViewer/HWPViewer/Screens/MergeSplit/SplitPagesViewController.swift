//
//  SplitPagesViewController.swift
//  HWPViewer
//
//  Split page picker (Figma "Selected (0)" 6978:109748, "Selected (3)" 6978:110099): nav title
//  "Selected (n)" + select-all checkbox, 3-column grid of page tiles (tap to toggle), "Continue (n)"
//  (gray at 0) → file name → loading → "Split HWP Successfully". The picked pages go into one new file.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class SplitPagesViewController: AppBaseViewController, ToolFlowScreen {
    private let item: FileItem
    private let renderer: HwpPageThumbnailRenderer
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var pageCount = 0
    private var selected = Set<Int>()
    private let selectAll = SelectAllButton(type: .custom)
    private let continueButton = MergeSplitUI.primaryButton("")
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())

    init(item: FileItem) {
        self.item = item
        renderer = HwpPageThumbnailRenderer(url: item.url)
        super.init(place: .mergeSplit, navigationConfigs: MergeSplitUI.navigationConfig(title: L10n.splitSelected(0)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        MergeSplitUI.addNavHairline(to: navigationView)
        selectAll.install(in: navigationView)
        selectAll.tapPublisher
            .sink { [weak self] _ in self?.toggleSelectAll() }
            .store(in: &cancellables)

        containerStackView.addArrangedSubview(collectionView)
        containerStackView.addArrangedSubview(nativeAdSlot) // above the Split bar
        loadingIndicator.color = AppColors.primary
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { $0.center.equalTo(collectionView) }
        collectionView.backgroundColor = AppColors.background
        collectionView.register(SplitPageCell.self, forCellWithReuseIdentifier: SplitPageCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 15.36, left: 0, bottom: 8, right: 0)

        MergeSplitUI.bottomBar(in: containerStackView, of: view, content: continueButton)
        setupAdvertiser(on: .splitPages)
        continueButton.tapPublisher
            .sink { [weak self] _ in self?.continueTapped() }
            .store(in: &cancellables)
        refreshSelectionUI()
        loadPages()
    }

    /// 3 columns: 15.36pt sides, 14.88pt between columns, 7.68pt between rows (Figma, 360pt frame).
    private func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 14.88
        layout.minimumLineSpacing = 7.68
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15.36, bottom: 0, right: 15.36)
        return layout
    }

    private func loadPages() {
        // The document opens (and paginates) before any page shows: say it is loading (ESI05-68).
        loadingIndicator.startAnimating()
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { loadingIndicator.stopAnimating() }
            do {
                try await HwpEngine.prepare()
                pageCount = try await renderer.open()
                collectionView.reloadData()
                refreshSelectionUI()
            } catch {
                ErrorPopup.present(from: self, message: ErrorPopup.message(for: error))
            }
        }
    }

    private func toggle(page: Int) {
        if selected.contains(page) { selected.remove(page) } else { selected.insert(page) }
        // Restyle the visible cell in place: reloading it would re-request its thumbnail.
        if let cell = collectionView.cellForItem(at: IndexPath(item: page - 1, section: 0)) as? SplitPageCell {
            cell.configure(page: page, selected: selected.contains(page), renderer: renderer)
        }
        refreshSelectionUI()
    }

    private func toggleSelectAll() {
        guard pageCount > 0 else { return }
        selected = selected.count == pageCount ? [] : Set(1...pageCount)
        for case let cell as SplitPageCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            cell.configure(page: indexPath.item + 1, selected: selected.contains(indexPath.item + 1), renderer: renderer)
        }
        refreshSelectionUI()
    }

    private func refreshSelectionUI() {
        navigationView.titleLabel.text = L10n.splitSelected(selected.count)
        selectAll.isOn = pageCount > 0 && selected.count == pageCount
        continueButton.setTitle(L10n.mergeContinue(selected.count), for: .normal)
        continueButton.isEnabled = !selected.isEmpty
    }

    /// Free users see the interstitial (`merge_split_screen`) at the tap that commits to the split, before
    /// the file-name popup — as OCR does. Not after the split: the result screen asks for a rating once, and
    /// an ad closing right before it would skip that prompt (`ad_gap_seconds`).
    private func continueTapped() {
        guard !selected.isEmpty else { return }
        guard !isPremium else { return askFileName() }
        SPNAdsManager.shared.interstitial.show(from: self, place: interstitialPlace) { [weak self] result in
            if case .didDismiss = result { RatePromptManager.shared.noteFullScreenAdDismissed() }
            self?.askFileName()
        }
    }

    private func askFileName() {
        guard !selected.isEmpty else { return }
        let ext = item.kind.rawValue
        let dialog = RenameDialog(title: L10n.mergeFileNameTitle, initialName: "", confirmTitle: L10n.popupOk)
        dialog.validator = { FileStore.shared.validateNewName($0, ext: ext)?.errorDescription }
        dialog.onConfirm = { [weak self] name in
            self?.runSplit(outputName: name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        present(dialog, animated: true)
    }

    private func runSplit(outputName: String) {
        let item = item
        let pages = selected.sorted()
        let loading = LoadingOverlayViewController(
            work: { [try await HwpMergeSplitService.shared.extract(item, pages: pages, outputName: outputName)] },
            onFinished: { [weak self] result in self?.finish(result) }
        )
        present(loading, animated: true)
    }

    private func finish(_ result: Result<[DocumentOutput], Error>) {
        switch result {
        case .success(let outputs):
            guard let output = outputs.first else { return }
            let done = ConvertResultViewController(outputURL: output.url, size: output.size, title: L10n.splitSuccessTitle,
                                                   titleFont: AppFonts.semibold(18), place: .mergeSplit,
                                                   nativePlace: .splitResult)
            navigationController?.pushViewController(done, animated: true)
        case .failure(let error):
            ErrorPopup.present(from: self, message: ErrorPopup.message(for: error))
        }
    }
}

extension SplitPagesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { pageCount }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SplitPageCell.identifier, for: indexPath) as! SplitPageCell
        let page = indexPath.item + 1
        cell.configure(page: page, selected: selected.contains(page), renderer: renderer)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        toggle(page: indexPath.item + 1)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 2 * 15.36 - 2 * 14.88) / 3)
        return CGSize(width: width, height: width * SplitPageCell.previewAspect + SplitPageCell.numberBlock)
    }
}
