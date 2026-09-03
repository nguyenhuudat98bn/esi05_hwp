//
//  DesignTokens.swift
//  HWPViewer
//
//  Colors / fonts from Figma (📙 PDF Reader → esi05, see docs/design-notes.md). Keep hard-coded values here.
//

import UIKit
import SPNComponent

enum AppColors {
    // Brand (Blue/500 family)
    static let primary = UIColor(hex: "#2E90FA")
    static let primaryLight = UIColor(hex: "#D1E9FF")      // active toolbar bg, selection
    static let primaryRing = UIColor(hex: "#0BA5EC")       // selected swatch ring
    static let primarySoft = UIColor(hex: "#F0F9FF")       // selected plan bg
    static let tabActive = UIColor(hex: "#0088FF")
    static let accentOrange = UIColor(hex: "#FF9C66")      // filled bookmark
    static let success = UIColor(hex: "#51AA4D")
    static let danger = UIColor(hex: "#F03F39")
    static let dangerSoft = UIColor(hex: "#FFEBEB")
    static let errorText = UIColor(hex: "#FF3B30")

    // Surfaces
    static let background = UIColor.white
    static let surface = UIColor.white
    static let surfaceMuted = UIColor(hex: "#ECECED")      // secondary button / search field
    static let surfaceCircle = UIColor(hex: "#F0F0F1")     // more-sheet icon circle
    static let cardGray = UIColor(hex: "#F3F3F3")
    static let border = UIColor(hex: "#CECFD2")
    static let divider = UIColor(hex: "#ECECED")
    static let viewerBackground = UIColor(hex: "#94979C")
    static let toolbarBackground = UIColor.white
    static let tabBarSelected = UIColor(hex: "#EDEDED")
    static let grabber = UIColor(hex: "#BFC3C6")
    static let dim = UIColor.black.withAlphaComponent(0.65)
    static let pageBadge = UIColor.black.withAlphaComponent(0.6)

    // Text
    static let textPrimary = UIColor(hex: "#181D27")
    static let textDark = UIColor(hex: "#1C2A33")
    static let textSegmentInactive = UIColor(hex: "#252B37")
    static let textToolbar = UIColor(hex: "#535862")
    static let textSecondary = UIColor(hex: "#717680")
    static let textTertiary = UIColor(hex: "#94979C")
    static let textTabInactive = UIColor(hex: "#1A1A1A")
    static let textPaywall = UIColor(hex: "#363A4E")
    static let textOnPrimary = UIColor.white

    // File kinds
    static let hwp = UIColor(hex: "#2E90FA")
    static let pdf = UIColor(hex: "#F04438")
    static let doc = UIColor(hex: "#3B34B6")

    // Gradients top→bottom (card) or left→right (banners); `pill` = solid "Go" pill color
    static let gradientEdit: [UIColor] = [UIColor(hex: "#357DF8"), UIColor(hex: "#91C8FE")]
    static let pillEdit = UIColor(hex: "#337BF2")
    static let gradientPdf: [UIColor] = [UIColor(hex: "#34B68F"), UIColor(hex: "#95F3D1")]
    static let pillPdf = UIColor(hex: "#2FB389")
    static let gradientDoc: [UIColor] = [UIColor(hex: "#3B34B6"), UIColor(hex: "#A5D1FB")]
    static let pillDoc = UIColor(hex: "#3B35B6")
    static let gradientPrint: [UIColor] = [UIColor(hex: "#9226EF"), UIColor(hex: "#95BEF3")]
    static let pillPrint = UIColor(hex: "#7523D8")
    static let gradientPremium: [UIColor] = [UIColor(hex: "#56CCF2"), UIColor(hex: "#2F80ED")]
    static let gradientContinue: [UIColor] = [UIColor(hex: "#1673FF"), UIColor(hex: "#69C5FB")]
    static let gradientBestOffer: [UIColor] = [UIColor(hex: "#FF9966"), UIColor(hex: "#FF5E62")]

    // Editor palettes (Figma toolbar variants). First entry = default selection.
    static let highlightSwatches = ["#FEB43F", "#E292FE", "#F4A4C0", "#A7C6FF", "#93E3FC"]
    static let textColorSwatches = ["#000000", "#FF320B", "#FF6A00", "#D65DFF", "#3A87FD"]
}

enum AppFonts {
    static func regular(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
    static func medium(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .medium) }
    static func semibold(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .semibold) }
    static func bold(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    /// Paywall title (SF Pro Condensed Bold in Figma).
    static func condensedBold(_ size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: .bold)
        if let descriptor = base.fontDescriptor.withDesign(.default)?.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.width: -0.2]
        ]) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }
}

enum AppMetrics {
    static let screenPadding: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let cellRadius: CGFloat = 10
    static let cellHeight: CGFloat = 62
    static let cellSpacing: CGFloat = 12
    static let buttonHeight: CGFloat = 48
    static let buttonRadius: CGFloat = 24
    static let tabBarHeight: CGFloat = 58
    static let tabBarWidth: CGFloat = 302
    static let popupRadius: CGFloat = 16
    static let sheetRadius: CGFloat = 16
    static let navHeight: CGFloat = 56
}
