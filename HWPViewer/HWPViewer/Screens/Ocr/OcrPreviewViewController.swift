//
//  OcrPreviewViewController.swift
//  HWPViewer
//
//  "OCR" preview (Figma 6985:111076): X header with hairline, the page image full width 26pt under
//  the header, bottom bar with "Convert to HWP" (+ "AD" corner badge for free users, Figma
//  6988:130067: an interstitial plays first). Convert → loading (6988:130059) → error screen
//  (6987:129718, "Try Again") or file name (7011:116206) → "Convert HWP Successfully" (7011:116139).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class OcrPreviewViewController: AppBaseViewController, ToolFlowScreen {
    private let page: UIImage
    private let imageView = UIImageView()
    private let convertButton = MergeSplitUI.primaryButton(L10n.ocrConvertToHwp)
    private let adBadge = UILabel()

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
        imageView.image = page
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIgnoresInvertColors = true
        content.addSubview(imageView)
        MergeSplitUI.bottomBar(in: view, content: convertButton)
        // Full width, 26pt under the header, as tall as the page needs (shrinks to fit short screens).
        let ratio = page.size.height / max(page.size.width, 1)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(26)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.width.equalToSuperview().priority(.high)
            make.height.equalTo(imageView.snp.width).multipliedBy(ratio)
            make.bottom.lessThanOrEqualToSuperview().inset(MergeSplitUI.bottomBarHeight + 16)
        }

        // "AD" corner tab: white 40%, top-right of the button, 42×23, rounded bottom-left / top-right 12.
        adBadge.text = L10n.ocrAdBadge
        adBadge.font = AppFonts.medium(16)
        adBadge.textColor = .white
        adBadge.textAlignment = .center
        adBadge.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        adBadge.layer.cornerRadius = 12
        adBadge.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
        adBadge.clipsToBounds = true
        convertButton.addSubview(adBadge)
        adBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.size.equalTo(CGSize(width: 42, height: 23))
        }
        adBadge.isHidden = isPremium

        convertButton.tapPublisher
            .sink { [weak self] _ in self?.convertTapped() }
            .store(in: &cancellables)
    }

    override func premiumStatusDidChange() {
        super.premiumStatusDidChange()
        adBadge.isHidden = isPremium
    }

    private func convertTapped() {
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
            askFileName(for: conversion)
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
                let done = ConvertResultViewController(outputURL: output.url, size: output.size, place: .ocr)
                navigationController?.pushViewController(done, animated: true)
            } catch {
                ErrorPopup.present(from: self, message: error.localizedDescription)
            }
        }
        present(dialog, animated: true)
    }
}
