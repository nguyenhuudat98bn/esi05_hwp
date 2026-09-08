//
//  ImportSheetViewController.swift
//  HWPViewer
//
//  Bottom sheet (Figma B3): "Import or convert your files to HWP" – Import file, PDF to HWP, DOC to HWP, native ad.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class ImportSheetViewController: UIViewController {
    var onImportHwp: (() -> Void)?
    var onConvert: ((ToolKind) -> Void)?

    private let dimView = UIView()
    private let sheet = UIView()
    private let adSlot = SPNNativeAdSlot()
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dimView.backgroundColor = AppColors.dim
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))

        sheet.backgroundColor = AppColors.surface
        sheet.layer.cornerRadius = 20
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        let grabber = UIView()
        grabber.backgroundColor = AppColors.grabber
        grabber.layer.cornerRadius = 2

        let title = UILabel()
        title.text = L10n.importTitle
        title.font = AppFonts.semibold(18)
        title.textColor = UIColor(hex: "#333333")
        title.numberOfLines = 0
        title.textAlignment = .center

        let importCard = ImportFileCard()
        let pdfCard = GradientCardView(tool: .pdfToHwp)
        let docCard = GradientCardView(tool: .docToHwp)
        let convertRow = UIStackView(arrangedSubviews: [pdfCard, docCard])
        convertRow.axis = .horizontal
        convertRow.spacing = 12
        convertRow.distribution = .fillEqually

        let grabberWrap = UIView()
        grabberWrap.addSubview(grabber)
        grabber.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(4)
        }
        let stack = UIStackView(arrangedSubviews: [grabberWrap, title, importCard, convertRow, adSlot])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.setCustomSpacing(16, after: grabberWrap)
        stack.setCustomSpacing(20, after: title)
        sheet.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        importCard.snp.makeConstraints { $0.height.equalTo(80) }
        convertRow.snp.makeConstraints { $0.height.equalTo(88) }

        importCard.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.finish { self?.onImportHwp?() } }.store(in: &cancellables)
        pdfCard.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.finish { self?.onConvert?(.pdfToHwp) } }.store(in: &cancellables)
        docCard.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.finish { self?.onConvert?(.docToHwp) } }.store(in: &cancellables)

        adSlot.attach(place: .importSheet, style: .native)

        sheet.transform = CGAffineTransform(translationX: 0, y: 400)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Runs alongside the presentation's cross-dissolve. Doing it in viewDidAppear meant the dim
        // faded in first and only then the sheet slid up — read as a delayed, two-step popup.
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4) {
            self.sheet.transform = .identity
        }
    }

    @objc private func close() {
        finish(nil)
    }

    private func finish(_ completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.sheet.transform = CGAffineTransform(translationX: 0, y: 400)
        }, completion: { _ in
            self.dismiss(animated: true) { completion?() }
        })
    }
}

/// Wide "Import file" card: blue gradient, faded import glyph on the left, text left-aligned beside it, round arrow button.
final class ImportFileCard: UIControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = AppMetrics.cardRadius
        clipsToBounds = true
        // Designer card art (328×80): gradient + tilted import glyph baked in; texts and the arrow pill sit on top.
        let background = UIImageView(image: Asset.Assets.App.imgCardImportBg.image)
        background.contentMode = .scaleAspectFill
        background.isUserInteractionEnabled = false
        addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let arrow = UIView()
        arrow.backgroundColor = AppColors.pillEdit
        arrow.layer.cornerRadius = 18
        arrow.isUserInteractionEnabled = false
        let arrowIcon = UIImageView(image: Asset.Assets.App.icArrowRightOutline.image.withRenderingMode(.alwaysTemplate))
        arrowIcon.tintColor = .white
        arrowIcon.contentMode = .scaleAspectFit
        arrow.addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints { $0.edges.equalToSuperview().inset(3) }
        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        let title = UILabel()
        title.text = L10n.importFile
        title.font = AppFonts.semibold(18)
        title.textColor = .white
        title.textAlignment = .left
        let subtitle = UILabel()
        subtitle.text = L10n.importFileSubtitle
        subtitle.font = AppFonts.regular(12)
        subtitle.textColor = .white
        subtitle.textAlignment = .left
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.8
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { make in
            // 72pt clears the tilted import glyph baked into the card art (Figma B3).
            make.leading.equalToSuperview().inset(72)
            make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}
