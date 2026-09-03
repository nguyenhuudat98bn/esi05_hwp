// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
internal enum L10n {
  /// Localizable.strings
  ///   HWPViewer
  /// 
  ///   Created by datnh on 01/4/24.
  internal static var applicationName: String { return L10n.tr("Localizable", "ApplicationName", fallback: "Nova Project") }
  /// Update Now
  internal static var updateNowButton: String { return L10n.tr("Localizable", "update_now_button", fallback: "Update Now") }
  /// A newer version of this app is available. Please update to continue using the app.
  internal static var updateRequiredMessage: String { return L10n.tr("Localizable", "update_required_message", fallback: "A newer version of this app is available. Please update to continue using the app.") }
  /// Update Required
  internal static var updateRequiredTitle: String { return L10n.tr("Localizable", "update_required_title", fallback: "Update Required") }
  /// Home
  internal static var homeTitle: String { return L10n.tr("Localizable", "Home.Title", fallback: "Home") }
  /// Next
  internal static var introduceNextButton: String { return L10n.tr("Localizable", "Introduce.NextButton", fallback: "Next") }
  /// Start
  internal static var introduceStartButton: String { return L10n.tr("Localizable", "Introduce.StartButton", fallback: "Start") }
  /// Step 1 title
  internal static var introduceStep1Title: String { return L10n.tr("Localizable", "Introduce.Step1.Title", fallback: "Step 1 title") }
  /// Step 2 title
  internal static var introduceStep2Title: String { return L10n.tr("Localizable", "Introduce.Step2.Title", fallback: "Step 2 title") }
  /// Step 3 title
  internal static var introduceStep3Title: String { return L10n.tr("Localizable", "Introduce.Step3.Title", fallback: "Step 3 title") }
  /// Done
  internal static var languageApplyButton: String { return L10n.tr("Localizable", "Language.ApplyButton", fallback: "Done") }
  /// Language applied successfully!
  internal static var languageApplySuccess: String { return L10n.tr("Localizable", "Language.ApplySuccess", fallback: "Language applied successfully!") }
  /// Select Language
  internal static var languageTitle: String { return L10n.tr("Localizable", "Language.Title", fallback: "Select Language") }
  /// Ads are about to be show...
  internal static var loadDataLoadTitle: String { return L10n.tr("Localizable", "LoadData.LoadTitle", fallback: "Ads are about to be show...") }
  /// Base project of Nova JSC
  internal static var loadDataSubTitle: String { return L10n.tr("Localizable", "LoadData.SubTitle", fallback: "Base project of Nova JSC") }
  /// Check Connection
  internal static var loadDataNetworkCheckConnection: String { return L10n.tr("Localizable", "LoadData.Network.CheckConnection", fallback: "Check Connection") }
  /// For the best app experience, please enable your Internet connection.
  internal static var loadDataNetworkDescription: String { return L10n.tr("Localizable", "LoadData.Network.Description", fallback: "For the best app experience, please enable your Internet connection.") }
  /// Internet connection lost
  internal static var loadDataNetworkTitle: String { return L10n.tr("Localizable", "LoadData.Network.Title", fallback: "Internet connection lost") }
  /// Use without Internet
  internal static var loadDataNetworkUseWithoutInternet: String { return L10n.tr("Localizable", "LoadData.Network.UseWithoutInternet", fallback: "Use without Internet") }
  /// Welcome back
  internal static var preloadAppOpenLoadTitle: String { return L10n.tr("Localizable", "PreloadAppOpen.LoadTitle", fallback: "Welcome back") }
  /// Week
  internal static var purchase1Week: String { return L10n.tr("Localizable", "Purchase.1Week", fallback: "Week") }
  /// Year
  internal static var purchase1Year: String { return L10n.tr("Localizable", "Purchase.1Year", fallback: "Year") }
  /// Edit PDF Text
  internal static var purchaseBenefit1: String { return L10n.tr("Localizable", "Purchase.Benefit1", fallback: "Edit PDF Text") }
  /// E-SIGN DOCUMENTS
  internal static var purchaseBenefit2: String { return L10n.tr("Localizable", "Purchase.Benefit2", fallback: "E-SIGN DOCUMENTS") }
  /// Convert Files to PDF
  internal static var purchaseBenefit3: String { return L10n.tr("Localizable", "Purchase.Benefit3", fallback: "Convert Files to PDF") }
  /// Advanced Editing Tools
  internal static var purchaseBenefit4: String { return L10n.tr("Localizable", "Purchase.Benefit4", fallback: "Advanced Editing Tools") }
  /// Remove Ads For Good
  internal static var purchaseBenefit5: String { return L10n.tr("Localizable", "Purchase.Benefit5", fallback: "Remove Ads For Good") }
  /// Continue
  internal static var purchaseButtonContinue: String { return L10n.tr("Localizable", "Purchase.ButtonContinue", fallback: "Continue") }
  /// Restore
  internal static var purchaseButtonRestore: String { return L10n.tr("Localizable", "Purchase.ButtonRestore", fallback: "Restore") }
  /// Transaction failed, please try again later
  internal static var purchaseFailedMessage: String { return L10n.tr("Localizable", "Purchase.FailedMessage", fallback: "Transaction failed, please try again later") }
  /// %@-day free trial
  internal static func purchaseFreeTrial(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Purchase.FreeTrial", String(describing: p1), fallback: "%@-day free trial")
  }
  /// %@/week
  internal static func purchasePricePerWeek(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Purchase.PricePerWeek", String(describing: p1), fallback: "%@/week")
  }
  /// Privacy Policy
  internal static var purchasePrivacyPolicy: String { return L10n.tr("Localizable", "Purchase.PrivacyPolicy", fallback: "Privacy Policy") }
  /// Successfully restored the PREMIUM version
  internal static var purchaseRestoreSuccessMessage: String { return L10n.tr("Localizable", "Purchase.RestoreSuccessMessage", fallback: "Successfully restored the PREMIUM version") }
  /// Congratulations, you have successfully upgraded to the PREMIUM version. Enjoy your experience!
  internal static var purchaseSuccessMessage: String { return L10n.tr("Localizable", "Purchase.SuccessMessage", fallback: "Congratulations, you have successfully upgraded to the PREMIUM version. Enjoy your experience!") }
  /// Terms of Use
  internal static var purchaseTermOfUse: String { return L10n.tr("Localizable", "Purchase.TermOfUse", fallback: "Terms of Use") }
  /// PREMIUM VERSION
  internal static var purchaseTitle: String { return L10n.tr("Localizable", "Purchase.Title", fallback: "PREMIUM VERSION") }
  /// Weekly
  internal static var purchaseWeekly: String { return L10n.tr("Localizable", "Purchase.Weekly", fallback: "Weekly") }
  /// Yearly
  internal static var purchaseYearly: String { return L10n.tr("Localizable", "Purchase.Yearly", fallback: "Yearly") }
  /// Convert to DOCX
  internal static var purchasesSlideConvertToDOCX: String { return L10n.tr("Localizable", "PurchasesSlide.ConvertToDOCX", fallback: "Convert to DOCX") }
  /// Convert to JPG
  internal static var purchasesSlideConvertToJPG: String { return L10n.tr("Localizable", "PurchasesSlide.ConvertToJPG", fallback: "Convert to JPG") }
  /// Convert to PDF
  internal static var purchasesSlideConvertToPDF: String { return L10n.tr("Localizable", "PurchasesSlide.ConvertToPDF", fallback: "Convert to PDF") }
  /// Documents
  internal static var purchasesSlideScanDocuments: String { return L10n.tr("Localizable", "PurchasesSlide.ScanDocuments", fallback: "Documents") }
  /// ID Cards
  internal static var purchasesSlideScanIDCards: String { return L10n.tr("Localizable", "PurchasesSlide.ScanIDCards", fallback: "ID Cards") }
  /// Passports
  internal static var purchasesSlideScanPassports: String { return L10n.tr("Localizable", "PurchasesSlide.ScanPassports", fallback: "Passports") }
  /// LET'S START
  internal static var purchasesSlideStep1ButtonTitle: String { return L10n.tr("Localizable", "PurchasesSlide.Step1.ButtonTitle", fallback: "LET'S START") }
  /// NOVA PROJECT
  internal static var purchasesSlideStep1SubTitle: String { return L10n.tr("Localizable", "PurchasesSlide.Step1.SubTitle", fallback: "NOVA PROJECT") }
  /// Welcome
  internal static var purchasesSlideStep1Title: String { return L10n.tr("Localizable", "PurchasesSlide.Step1.Title", fallback: "Welcome") }
  /// CONTINUE
  internal static var purchasesSlideStep2ButtonTitle: String { return L10n.tr("Localizable", "PurchasesSlide.Step2.ButtonTitle", fallback: "CONTINUE") }
  /// Step2 SubTitle
  internal static var purchasesSlideStep2SubTitle: String { return L10n.tr("Localizable", "PurchasesSlide.Step2.SubTitle", fallback: "Step2 SubTitle") }
  /// Step2 Title
  internal static var purchasesSlideStep2Title: String { return L10n.tr("Localizable", "PurchasesSlide.Step2.Title", fallback: "Step2 Title") }
  /// CONTINUE
  internal static var purchasesSlideStep3ButtonTitle: String { return L10n.tr("Localizable", "PurchasesSlide.Step3.ButtonTitle", fallback: "CONTINUE") }
  /// Step3 SubTitle
  internal static var purchasesSlideStep3SubTitle: String { return L10n.tr("Localizable", "PurchasesSlide.Step3.SubTitle", fallback: "Step3 SubTitle") }
  /// Step3 Title
  internal static var purchasesSlideStep3Title: String { return L10n.tr("Localizable", "PurchasesSlide.Step3.Title", fallback: "Step3 Title") }
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = NSCustomLocalizedString(key, table, value)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
