//
//  FileActionSheet.swift
//  HWPViewer
//
//  "More" sheet (Figma E1): file header + Rename / Share / Print / Delete.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

enum FileAction: CaseIterable {
    case edit, rename, share, print, delete

    var title: String {
        switch self {
        case .edit: return L10n.fileActionEdit
        case .rename: return L10n.fileActionRename
        case .share: return L10n.fileActionShare
        case .print: return L10n.fileActionPrint
        case .delete: return L10n.fileActionDelete
        }
    }

    var icon: UIImage? {
        switch self {
        case .edit: return Asset.Assets.App.icTbItalic.image
        case .rename: return Asset.Assets.App.icMoreRenameEdit.image
        case .share: return Asset.Assets.App.icMoreShare.image
        case .print: return Asset.Assets.App.icMorePrint.image
        case .delete: return Asset.Assets.App.icMoreDelete.image
        }
    }

    var isDestructive: Bool { self == .delete }
}

final class FileActionSheet: UIViewController {
    var onAction: ((FileAction) -> Void)?
    var onBookmark: (() -> Void)?

    private var item: FileItem
    private let actions: [FileAction]
    private let dimView = UIView()
    private let sheet = UIView()
    private let bookmarkButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()

    init(item: FileItem, actions: [FileAction] = [.rename, .share, .print, .delete]) {
        self.item = item
        self.actions = actions
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
        sheet.layer.cornerRadius = 24
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }

        // Header
        let iconView = FileKindIconView()
        iconView.kind = item.kind
        let nameLabel = UILabel()
        nameLabel.text = item.displayName
        nameLabel.font = AppFonts.semibold(15)
        nameLabel.textColor = AppColors.textPrimary
        nameLabel.lineBreakMode = .byTruncatingMiddle
        let metaLabel = UILabel()
        metaLabel.text = item.metaText
        metaLabel.font = AppFonts.regular(12)
        metaLabel.textColor = AppColors.textSecondary
        let textStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        updateBookmark()
        bookmarkButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                onBookmark?()
                item.isBookmarked.toggle()
                updateBookmark()
            }
            .store(in: &cancellables)

        let header = UIView()
        header.addSubview(iconView)
        header.addSubview(textStack)
        header.addSubview(bookmarkButton)
        iconView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 34, height: 40))
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalTo(bookmarkButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        bookmarkButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        let divider = UIView()
        divider.backgroundColor = AppColors.divider
        divider.snp.makeConstraints { $0.height.equalTo(1) }

        let rows = actions.map { action -> UIControl in
            let row = FileActionRow(action: action)
            row.tapPublisher.receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.finish { self?.onAction?(action) } }
                .store(in: &cancellables)
            return row
        }

        let grabber = UIView()
        grabber.backgroundColor = AppColors.grabber
        grabber.layer.cornerRadius = 2
        grabber.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalTo(4)
        }

        let stack = UIStackView(arrangedSubviews: [grabber, header, divider] + rows)
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .fill
        stack.setCustomSpacing(16, after: grabber)
        stack.setCustomSpacing(16, after: header)
        stack.setCustomSpacing(8, after: divider)
        sheet.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        grabber.snp.makeConstraints { $0.centerX.equalToSuperview() }
        sheet.transform = CGAffineTransform(translationX: 0, y: 400)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4) {
            self.sheet.transform = .identity
        }
    }

    private func updateBookmark() {
        bookmarkButton.setImage((item.isBookmarked ? Asset.Assets.App.icBookmarkFilled.image : Asset.Assets.App.icBookmarkOutline.image).withRenderingMode(.alwaysTemplate), for: .normal)
        bookmarkButton.tintColor = item.isBookmarked ? AppColors.accentOrange : AppColors.textTertiary
    }

    @objc private func close() { finish(nil) }

    private func finish(_ completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.sheet.transform = CGAffineTransform(translationX: 0, y: 400)
        }, completion: { _ in
            self.dismiss(animated: true) { completion?() }
        })
    }
}

final class FileActionRow: UIControl {
    init(action: FileAction) {
        super.init(frame: .zero)
        let color = action.isDestructive ? AppColors.danger : AppColors.textDark
        let circle = UIView()
        circle.backgroundColor = action.isDestructive ? AppColors.dangerSoft : AppColors.surfaceCircle
        circle.layer.cornerRadius = 20
        circle.isUserInteractionEnabled = false
        let icon = UIImageView(image: action.icon?.withRenderingMode(.alwaysTemplate))
        icon.tintColor = color
        icon.contentMode = .scaleAspectFit
        circle.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        let label = UILabel()
        label.text = action.title
        label.font = AppFonts.medium(14)
        label.textColor = color
        addSubview(circle)
        addSubview(label)
        circle.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(circle.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        let line = UIView()
        line.backgroundColor = AppColors.divider
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        snp.makeConstraints { $0.height.equalTo(56) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? AppColors.surfaceMuted : .clear }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}
