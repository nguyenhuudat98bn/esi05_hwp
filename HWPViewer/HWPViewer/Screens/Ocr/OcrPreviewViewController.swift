//
//  OcrPreviewViewController.swift
//  HWPViewer
//
//  "OCR" preview (Figma 6985:111076): X header with hairline, the page image full width 26pt under
//  the header, bottom bar with "Convert to HWP" (free users: an interstitial plays first; the
//  Figma "AD" corner badge 6988:130067 was dropped on request). Convert → loading (6988:130059) → error screen
//  (6987:129718, "Try Again") or file name (7011:116206) → "Convert HWP Successfully" (7011:116139).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class OcrPreviewViewController: AppBaseViewController, ToolFlowScreen {
    private let page: UIImage
    private lazy var pageView = OcrZoomableImageView(image: page)
    private let convertButton = MergeSplitUI.primaryButton(L10n.ocrConvertToHwp)
    /// Converted page not saved yet: the file-name dialog was cancelled. Convert again goes straight
    /// back to the dialog instead of another interstitial and another recognition pass.
    private var unsavedConversion: OcrConversion?

    init(page: UIImage) {
        self.page = page
        super.init(place: .ocr, navigationConfigs: SPNNavigationConfiguration(
            title: "", hasBackButton: true, backIcon: Asset.Assets.App.icEditorCloseX.image,
            tintColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.snp.updateConstraints { $0.height.equalTo(AppMetrics.navHeight) }
        MergeSplitUI.addNavHairline(to: navigationView)
        let content = UIView()
        containerStackView.addArrangedSubview(content)
        content.addSubview(pageView)
        containerStackView.addArrangedSubview(nativeAdSlot) // above the Convert bar
        MergeSplitUI.bottomBar(in: containerStackView, of: view, content: convertButton)
        setupAdvertiser(on: .ocrPreview)
        // 26pt under the header down to the ad / bottom bar; the page fills the width at 1× and zooms (ESI05-54).
        pageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(26)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }

        convertButton.tapPublisher
            .sink { [weak self] _ in self?.convertTapped() }
            .store(in: &cancellables)
    }

    private func convertTapped() {
        if let unsavedConversion { return askFileName(for: unsavedConversion) }
        guard !isPremium else { return runConversion() }
        SPNAdsManager.shared.interstitial.show(from: self, place: .ocr) { [weak self] result in
            if case .didDismiss = result { RatePromptManager.shared.noteFullScreenAdDismissed() }
            self?.runConversion()
        }
    }

    private func runConversion() {
        let page = page
        let loading = LoadingOverlayViewController(
            work: { try await OcrToHwpService.shared.convert(page) },
            onFinished: { [weak self] result in self?.finish(result) }
        )
        present(loading, animated: true)
    }

    private func finish(_ result: Result<OcrConversion, Error>) {
        switch result {
        case .success(let conversion):
            unsavedConversion = conversion
            askFileName(for: conversion)
        case .failure(let error as HwpFontError) where error == .network:
            // The engine fonts could not be fetched: offline dialog with Try Again (ESI05-56).
            logger("[OCR] failed offline")
            OfflinePopup.present(from: self) { [weak self] in self?.runConversion() }
        case .failure(let error):
            logger("[OCR] failed: \(error)")
            let failure = DocumentErrorViewController(place: .ocr, content: .ocr)
            failure.onAction = { [weak failure] in failure?.navigationController?.popViewController(animated: true) }
            navigationController?.pushViewController(failure, animated: true)
        }
    }

    private func askFileName(for conversion: OcrConversion) {
        let dialog = RenameDialog(title: L10n.mergeFileNameTitle, initialName: "", confirmTitle: L10n.popupOk)
        dialog.validator = { FileStore.shared.validateNewName($0, ext: "hwp")?.errorDescription }
        dialog.onConfirm = { [weak self] name in
            guard let self else { return }
            do {
                let output = try OcrToHwpService.shared.save(conversion, named: name.trimmingCharacters(in: .whitespacesAndNewlines))
                unsavedConversion = nil
                let done = ConvertResultViewController(outputURL: output.url, size: output.size, place: .ocr,
                                                       nativePlace: .ocrResult)
                navigationController?.pushViewController(done, animated: true)
            } catch {
                ErrorPopup.present(from: self, message: ErrorPopup.message(for: error))
            }
        }
        present(dialog, animated: true)
    }
}
