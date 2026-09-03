// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Assets {
    internal enum App {
      internal static let icAngleLeft = ImageAsset(name: "App/ic_angle_left")
      internal static let icArrowFilledRight = ImageAsset(name: "App/ic_arrow_filled_right")
      internal static let icArrowRightOutline = ImageAsset(name: "App/ic_arrow_right_outline")
      internal static let icBookmarkFilled = ImageAsset(name: "App/ic_bookmark_filled")
      internal static let icBookmarkOutline = ImageAsset(name: "App/ic_bookmark_outline")
      internal static let icCancelX = ImageAsset(name: "App/ic_cancel_x")
      internal static let icCardEditHwpVector = ImageAsset(name: "App/ic_card_edit_hwp_vector")
      internal static let icCardPdfReader = ImageAsset(name: "App/ic_card_pdf_reader")
      internal static let icCardPrint = ImageAsset(name: "App/ic_card_print")
      internal static let icCardWordDoc = ImageAsset(name: "App/ic_card_word_doc")
      internal static let icCaretDown = ImageAsset(name: "App/ic_caret_down")
      internal static let icCloseCircle = ImageAsset(name: "App/ic_close_circle")
      internal static let icCrown = ImageAsset(name: "App/ic_crown")
      internal static let icEditorCloseX = ImageAsset(name: "App/ic_editor_close_x")
      internal static let icFileBody = ImageAsset(name: "App/ic_file_body")
      internal static let icFileFold = ImageAsset(name: "App/ic_file_fold")
      internal static let icFileGlyphHwp = ImageAsset(name: "App/ic_file_glyph_hwp")
      internal static let icFileGlyphPdf = ImageAsset(name: "App/ic_file_glyph_pdf")
      internal static let icImportSolid = ImageAsset(name: "App/ic_import_solid")
      internal static let icMore2Line = ImageAsset(name: "App/ic_more_2_line")
      internal static let icMoreDelete = ImageAsset(name: "App/ic_more_delete")
      internal static let icMorePrint = ImageAsset(name: "App/ic_more_print")
      internal static let icMoreRenameEdit = ImageAsset(name: "App/ic_more_rename_edit")
      internal static let icMoreShare = ImageAsset(name: "App/ic_more_share")
      internal static let icPaywallArrowRight = ImageAsset(name: "App/ic_paywall_arrow_right")
      internal static let icPaywallBestOfferRibbon = ImageAsset(name: "App/ic_paywall_best_offer_ribbon")
      internal static let icPaywallCheckWhite = ImageAsset(name: "App/ic_paywall_check_white")
      internal static let icPaywallCloseTimes = ImageAsset(name: "App/ic_paywall_close_times")
      internal static let icPaywallFeatureCheck = ImageAsset(name: "App/ic_paywall_feature_check")
      internal static let icPaywallFeatureCross = ImageAsset(name: "App/ic_paywall_feature_cross")
      internal static let icRoundPlus = ImageAsset(name: "App/ic_round_plus")
      internal static let icSearch = ImageAsset(name: "App/ic_search")
      internal static let icSettingsCertificate = ImageAsset(name: "App/ic_settings_certificate")
      internal static let icSettingsLanguage = ImageAsset(name: "App/ic_settings_language")
      internal static let icSettingsShare = ImageAsset(name: "App/ic_settings_share")
      internal static let icSettingsShieldCheck = ImageAsset(name: "App/ic_settings_shield_check")
      internal static let icSettingsShieldUser = ImageAsset(name: "App/ic_settings_shield_user")
      internal static let icSettingsStar = ImageAsset(name: "App/ic_settings_star")
      internal static let icSettingsWallet = ImageAsset(name: "App/ic_settings_wallet")
      internal static let icTabHomeFilled = ImageAsset(name: "App/ic_tab_home_filled")
      internal static let icTabSettingsFilled = ImageAsset(name: "App/ic_tab_settings_filled")
      internal static let icTabTools = ImageAsset(name: "App/ic_tab_tools")
      internal static let icTbAlignRight = ImageAsset(name: "App/ic_tb_align_right")
      internal static let icTbBold = ImageAsset(name: "App/ic_tb_bold")
      internal static let icTbColorNoneSlash = ImageAsset(name: "App/ic_tb_color_none_slash")
      internal static let icTbColorPickerGradient = ImageAsset(name: "App/ic_tb_color_picker_gradient")
      internal static let icTbFontMinus = ImageAsset(name: "App/ic_tb_font_minus")
      internal static let icTbFontPlus = ImageAsset(name: "App/ic_tb_font_plus")
      internal static let icTbHighlight = ImageAsset(name: "App/ic_tb_highlight")
      internal static let icTbItalic = ImageAsset(name: "App/ic_tb_italic")
      internal static let icTbRedo = ImageAsset(name: "App/ic_tb_redo")
      internal static let icTbStrikethrough = ImageAsset(name: "App/ic_tb_strikethrough")
      internal static let icTbTextColor = ImageAsset(name: "App/ic_tb_text_color")
      internal static let icTbUnderline = ImageAsset(name: "App/ic_tb_underline")
      internal static let icTbUndo = ImageAsset(name: "App/ic_tb_undo")
      internal static let icToastCancel16 = ImageAsset(name: "App/ic_toast_cancel_16")
      internal static let icUpload = ImageAsset(name: "App/ic_upload")
      internal static let icViewerMoreVertical = ImageAsset(name: "App/ic_viewer_more_vertical")
      internal static let imgEmptyNoFiles = ImageAsset(name: "App/img_empty_no_files")
      internal static let imgNoResultFoundVector = ImageAsset(name: "App/img_no_result_found_vector")
      internal static let imgOffline = ImageAsset(name: "App/img_offline")
      internal static let imgPaywallHeaderBg = ImageAsset(name: "App/img_paywall_header_bg")
      internal static let imgPaywallHero = ImageAsset(name: "App/img_paywall_hero")
      internal static let imgPremiumBannerBg = ImageAsset(name: "App/img_premium_banner_bg")
      internal static let imgPremiumBannerCrown = ImageAsset(name: "App/img_premium_banner_crown")
      internal static let imgPremiumBannerSparkle = ImageAsset(name: "App/img_premium_banner_sparkle")
      internal static let imgPremiumBannerSparkle2 = ImageAsset(name: "App/img_premium_banner_sparkle2")
      internal static let imgSaveChangesFolder = ImageAsset(name: "App/img_save_changes_folder")
    }
    internal enum Intro {
      internal static let icSwipe = ImageAsset(name: "ic_swipe")
      internal static let imgIntro1 = ImageAsset(name: "img_intro_1")
      internal static let imgIntro2 = ImageAsset(name: "img_intro_2")
      internal static let imgIntro3 = ImageAsset(name: "img_intro_3")
      internal static let imgIntroKr1 = ImageAsset(name: "img_intro_kr_1")
      internal static let imgIntroKr2 = ImageAsset(name: "img_intro_kr_2")
      internal static let imgIntroKr3 = ImageAsset(name: "img_intro_kr_3")
    }
    internal enum Language {
      internal static let icBack = ImageAsset(name: "ic_back")
      internal static let icCheck = ImageAsset(name: "ic_check")
      internal static let icDeselect = ImageAsset(name: "ic_deselect")
      internal static let icSelect = ImageAsset(name: "ic_select")
    }
    internal enum Purchases {
      internal static let bgBestValue = ImageAsset(name: "bg_best_value")
      internal static let bgPurchase = ImageAsset(name: "bg_purchase")
      internal static let icBenefitAdvanced = ImageAsset(name: "ic_benefit_advanced")
      internal static let icBenefitConvert = ImageAsset(name: "ic_benefit_convert")
      internal static let icBenefitEdit = ImageAsset(name: "ic_benefit_edit")
      internal static let icBenefitRemoveAds = ImageAsset(name: "ic_benefit_remove_ads")
      internal static let icBenefitSign = ImageAsset(name: "ic_benefit_sign")
      internal static let icClose = ImageAsset(name: "ic_close")
      internal static let icConvertDoc = ImageAsset(name: "ic_convert_doc")
      internal static let icConvertJpg = ImageAsset(name: "ic_convert_jpg")
      internal static let icConvertPdf = ImageAsset(name: "ic_convert_pdf")
      internal static let icRadioSelected = ImageAsset(name: "ic_radio_selected")
      internal static let icRadioUnselected = ImageAsset(name: "ic_radio_unselected")
      internal static let icScanDocs = ImageAsset(name: "ic_scan_docs")
      internal static let icScanIdcard = ImageAsset(name: "ic_scan_idcard")
      internal static let icScanPassport = ImageAsset(name: "ic_scan_passport")
      internal static let imgPurchaseStar = ImageAsset(name: "img_purchase_star")
    }
    internal enum Splash {
      internal static let logo = ImageAsset(name: "logo")
      internal static let splashBg = ImageAsset(name: "splash_bg")
    }
    internal static let icImageConvertCloseTip = ImageAsset(name: "ic_image_convert_close_tip")
  }
  internal enum Colors {
    internal static let colorFF2024 = ColorAsset(name: "ColorFF2024")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
internal extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
