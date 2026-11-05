//
//  ViewerEndOfDocumentAdView.swift
//  HWPViewer
//
//  Native ad after the last page of the document (place "view_last_page", as np12 Android's
//  ReaderEndOfDocumentAd): one more "page" the reader scrolls into, not a bar pinned over the
//  content. The kit's canvas lays it out under the pages (`DocumentCanvasCoordinator.setEndAccessory`)
//  and reserves `reservedHeight` for it.
//  - Takes no room until an ad is actually shown: disabled place, premium, no fill → the document
//    ends as usual, no blank tail.
//  - Read mode only (the host passes `isVisible = false` while editing).
//  - Styled like a page: white sheet with the pages' side margins and shadow, ad inset inside.
//  - Leaves room under the sheet for the floating "1/2" page badge, so the ad is never covered.
//

import UIKit
import SnapKit
import SPNComponent

final class ViewerEndOfDocumentAdView: UIView {
    /// Called whenever `reservedHeight` changes (ad shown / hidden, read ↔ edit).
    var onReservedHeightChanged: ((CGFloat) -> Void)?

    /// Height the canvas must reserve under the last page; 0 when nothing is shown.
    private(set) var reservedHeight: CGFloat = 0

    /// Shown only while the host is in read mode.
    var isVisible = true {
        didSet { updateReservedHeight() }
    }

    private let sheet = UIView()
    private let slot = SPNNativeAdSlot()
    private var isShowingAd = false

    /// Pages are inset 12pt from the viewport edges in the kit's canvas.
    private static let sideMargin: CGFloat = 12
    private static let sheetPadding: CGFloat = 6
    /// The page badge floats 26pt above the bottom bar and is 25pt tall; the canvas already adds
    /// a 14pt page gap under this view.
    private static let badgeClearance: CGFloat = 26 + 25 + 8 - 14

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        sheet.backgroundColor = .white
        sheet.layer.shadowColor = UIColor.black.cgColor
        sheet.layer.shadowOpacity = 0.18
        sheet.layer.shadowRadius = 3
        sheet.layer.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Self.sideMargin)
            // Height comes from the slot (template height); the badge clearance stays empty below.
        }
        sheet.addSubview(slot)
        slot.snp.makeConstraints { $0.edges.equalToSuperview().inset(Self.sheetPadding) }
        slot.onAdStateChanged = { [weak self] isShowing in
            self?.isShowingAd = isShowing
            self?.updateReservedHeight()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Loads the ad (no-op for premium users: the slot hides itself and nothing is reserved).
    func attach() {
        guard !SPNSession.shared.isPremium else { return }
        slot.attach(place: .viewLastPage)
    }

    func detach() {
        slot.detach()
        isShowingAd = false
        updateReservedHeight()
    }

    private func updateReservedHeight() {
        let height: CGFloat
        if isVisible, isShowingAd, let place = slot.place {
            let slotHeight = place.nativeTemplateSize.defaultHeight + 2 * slot.contentInset
            height = slotHeight + 2 * Self.sheetPadding + Self.badgeClearance
        } else {
            height = 0
        }
        guard height != reservedHeight else { return }
        reservedHeight = height
        onReservedHeightChanged?(height)
    }
}
