//
//  HwpEditHeaderView.swift
//  HWPViewer
//
//  Edit-mode header (Figma F2): X on the left, "Save" pill on the right.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class HwpEditHeaderView: UIView {
    var onClose: (() -> Void)?
    var onSave: (() -> Void)?

    private let closeButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.surface
        let line = UIView()
        line.backgroundColor = AppColors.divider
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        closeButton.setImage(Asset.Assets.App.icEditorCloseX.image.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppColors.textPrimary
        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        saveButton.setTitle(L10n.viewerSave, for: .normal)
        saveButton.titleLabel?.font = AppFonts.medium(12)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = AppColors.primary
        saveButton.layer.cornerRadius = 16
        addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 68, height: 32))
        }
        closeButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onClose?() }.store(in: &cancellables)
        saveButton.tapPublisher
            .throttle(for: .seconds(0.35), scheduler: RunLoop.main, latest: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onSave?() }.store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setSaveEnabled(_ enabled: Bool) {
        saveButton.isEnabled = enabled
        saveButton.alpha = enabled ? 1 : 0.5
    }
}
