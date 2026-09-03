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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

/// Wide "Import file" card: blue gradient, faded import glyph on the left, text right-aligned, round arrow button.
final class ImportFileCard: UIControl {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = AppMetrics.cardRadius
        clipsToBounds = true
        gradient.colors = AppColors.gradientEdit.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradient)

        let glyph = UIImageView(image: Asset.Assets.App.icImportSolid.image.withRenderingMode(.alwaysTemplate))
        glyph.tintColor = UIColor.white.withAlphaComponent(0.35)
        glyph.contentMode = .scaleAspectFit
        glyph.transform = CGAffineTransform(rotationAngle: 10.9 * .pi / 180)
        glyph.isUserInteractionEnabled = false
        addSubview(glyph)
        glyph.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(-28)
            make.top.equalToSuperview().inset(4)
            make.size.equalTo(81)
        }

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
        title.textAlignment = .right
        let subtitle = UILabel()
        subtitle.text = L10n.importFileSubtitle
        subtitle.font = AppFonts.regular(12)
        subtitle.textColor = .white
        subtitle.textAlignment = .right
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.trailing.equalTo(arrow.snp.leading).offset(-12)
            make.leading.greaterThanOrEqualToSuperview().inset(60)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}
