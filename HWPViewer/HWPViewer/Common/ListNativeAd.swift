//
//  ListNativeAd.swift
//  HWPViewer
//
//  Native inline ad inserted as the 2nd row of a file list (Home tabs, Search, Select File).
//  One `SPNNativeAdSlot` per screen is kept alive by `ListAdInserter`; the table cell only hosts it,
//  so scrolling / reloads never re-request the ad. The row collapses when there is nothing to show.
//

import UIKit
import SnapKit
import SPNComponent

@MainActor
final class ListAdInserter {
    static let adRow = 1
    static let rowSpacing: CGFloat = 12

    let place: SPNAdPlace
    let slot = SPNNativeAdSlot()
    /// Called when the ad row should appear / disappear (reload the table).
    var onChange: (() -> Void)?

    private var attached = false

    init(place: SPNAdPlace) {
        self.place = place
        slot.contentInset = 0
        slot.showsSkeleton = true
        slot.onAdStateChanged = { [weak self] _ in self?.onChange?() }
    }

    /// Requests the ad once. Safe to call again (no-op after the first attach).
    func attachIfNeeded() {
        guard !attached, !SPNSession.shared.isPremium else { return }
        attached = true
        slot.attach(place: place, style: .inline)
    }

    func detach() {
        attached = false
        slot.detach()
        onChange?()
    }

    /// The ad row exists only when the slot has something (skeleton or ad) and the list has ≥ 1 item.
    func hasAdRow(itemCount: Int) -> Bool {
        attached && !slot.isHidden && itemCount >= 1
    }

    func rowCount(itemCount: Int) -> Int {
        itemCount + (hasAdRow(itemCount: itemCount) ? 1 : 0)
    }

    func isAdRow(_ row: Int, itemCount: Int) -> Bool {
        hasAdRow(itemCount: itemCount) && row == Self.adRow
    }

    /// Maps a table row back to the item index (nil for the ad row).
    func itemIndex(for row: Int, itemCount: Int) -> Int? {
        guard hasAdRow(itemCount: itemCount) else { return row }
        if row == Self.adRow { return nil }
        return row > Self.adRow ? row - 1 : row
    }

    var adRowHeight: CGFloat {
        place.nativeTemplateSize.defaultHeight + Self.rowSpacing
    }
}

final class NativeAdTableCell: UITableViewCell {
    static let identifier = "NativeAdTableCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Hosts the screen's slot. The slot is moved (not copied) so only one instance exists.
    func host(_ slot: SPNNativeAdSlot) {
        guard slot.superview !== contentView else { return }
        slot.removeFromSuperview()
        contentView.addSubview(slot)
        slot.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(ListAdInserter.rowSpacing / 2)
            make.bottom.equalToSuperview().inset(ListAdInserter.rowSpacing / 2).priority(.high)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
    }
}
