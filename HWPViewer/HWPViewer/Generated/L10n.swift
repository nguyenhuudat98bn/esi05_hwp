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
  internal static var applicationName: String { return L10n.tr("Localizable", "ApplicationName", fallback: "HWP Viewer - Hangul Reader") }
  /// Update Now
  internal static var updateNowButton: String { return L10n.tr("Localizable", "update_now_button", fallback: "Update Now") }
  /// A newer version of this app is available. Please update to continue using the app.
  internal static var updateRequiredMessage: String { return L10n.tr("Localizable", "update_required_message", fallback: "A newer version of this app is available. Please update to continue using the app.") }
  /// Update Required
  internal static var updateRequiredTitle: String { return L10n.tr("Localizable", "update_required_title", fallback: "Update Required") }
  /// Done
  internal static var commonDone: String { return L10n.tr("Localizable", "Common.Done", fallback: "Done") }
  /// Loading...
  internal static var commonLoading: String { return L10n.tr("Localizable", "Common.Loading", fallback: "Loading...") }
  /// Next
  internal static var commonNext: String { return L10n.tr("Localizable", "Common.Next", fallback: "Next") }
  /// Converting...
  internal static var convertConverting: String { return L10n.tr("Localizable", "Convert.Converting", fallback: "Converting...") }
  /// Couldn't convert this file. Please try again.
  internal static var convertFailed: String { return L10n.tr("Localizable", "Convert.Failed", fallback: "Couldn't convert this file. Please try again.") }
  /// Convert to HWP
  internal static var convertTitle: String { return L10n.tr("Localizable", "Convert.Title", fallback: "Convert to HWP") }
  /// Back to Home
  internal static var convertErrorBackHome: String { return L10n.tr("Localizable", "Convert.Error.BackHome", fallback: "Back to Home") }
  /// This .doc file uses the old Word 97-2003 format. Open it in Word, save it as .docx and try again.
  internal static var convertErrorLegacyDoc: String { return L10n.tr("Localizable", "Convert.Error.LegacyDoc", fallback: "This .doc file uses the old Word 97-2003 format. Open it in Word, save it as .docx and try again.") }
  /// Oops! Something went wrong
  internal static var convertErrorMessage: String { return L10n.tr("Localizable", "Convert.Error.Message", fallback: "Oops! Something went wrong") }
  /// Back Home
  internal static var convertSuccessBackHome: String { return L10n.tr("Localizable", "Convert.Success.BackHome", fallback: "Back Home") }
  /// Name
  internal static var convertSuccessName: String { return L10n.tr("Localizable", "Convert.Success.Name", fallback: "Name") }
  /// Open
  internal static var convertSuccessOpen: String { return L10n.tr("Localizable", "Convert.Success.Open", fallback: "Open") }
  /// Path
  internal static var convertSuccessPath: String { return L10n.tr("Localizable", "Convert.Success.Path", fallback: "Path") }
  /// Size
  internal static var convertSuccessSize: String { return L10n.tr("Localizable", "Convert.Success.Size", fallback: "Size") }
  /// Convert HWP Successfully
  internal static var convertSuccessTitle: String { return L10n.tr("Localizable", "Convert.Success.Title", fallback: "Convert HWP Successfully") }
  /// Delete
  internal static var fileActionDelete: String { return L10n.tr("Localizable", "FileAction.Delete", fallback: "Delete") }
  /// Edit
  internal static var fileActionEdit: String { return L10n.tr("Localizable", "FileAction.Edit", fallback: "Edit") }
  /// Print
  internal static var fileActionPrint: String { return L10n.tr("Localizable", "FileAction.Print", fallback: "Print") }
  /// Rename
  internal static var fileActionRename: String { return L10n.tr("Localizable", "FileAction.Rename", fallback: "Rename") }
  /// Share
  internal static var fileActionShare: String { return L10n.tr("Localizable", "FileAction.Share", fallback: "Share") }
  /// Special offer
  internal static var giftBoxTitle: String { return L10n.tr("Localizable", "GiftBox.Title", fallback: "Special offer") }
  /// Home
  internal static var homeTitle: String { return L10n.tr("Localizable", "Home.Title", fallback: "Home") }
  /// DOC to HWP
  internal static var homeCardDocToHwp: String { return L10n.tr("Localizable", "Home.Card.DocToHwp", fallback: "DOC to HWP") }
  /// Edit HWP
  internal static var homeCardEditHwp: String { return L10n.tr("Localizable", "Home.Card.EditHwp", fallback: "Edit HWP") }
  /// Go
  internal static var homeCardGo: String { return L10n.tr("Localizable", "Home.Card.Go", fallback: "Go") }
  /// PDF to HWP
  internal static var homeCardPdfToHwp: String { return L10n.tr("Localizable", "Home.Card.PdfToHwp", fallback: "PDF to HWP") }
  /// Print
  internal static var homeCardPrint: String { return L10n.tr("Localizable", "Home.Card.Print", fallback: "Print") }
  /// Convert DOC to HWP
  internal static var homeCardDocToHwpSubtitle: String { return L10n.tr("Localizable", "Home.Card.DocToHwp.Subtitle", fallback: "Convert DOC to HWP") }
  /// Edit HWP files easily
  internal static var homeCardEditHwpSubtitle: String { return L10n.tr("Localizable", "Home.Card.EditHwp.Subtitle", fallback: "Edit HWP files easily") }
  /// Convert PDF to HWP
  internal static var homeCardPdfToHwpSubtitle: String { return L10n.tr("Localizable", "Home.Card.PdfToHwp.Subtitle", fallback: "Convert PDF to HWP") }
  /// Print document
  internal static var homeCardPrintSubtitle: String { return L10n.tr("Localizable", "Home.Card.Print.Subtitle", fallback: "Print document") }
  /// No bookmarked files.
  internal static var homeEmptyBookmark: String { return L10n.tr("Localizable", "Home.Empty.Bookmark", fallback: "No bookmarked files.") }
  /// Import File
  internal static var homeEmptyImport: String { return L10n.tr("Localizable", "Home.Empty.Import", fallback: "Import File") }
  /// No recent files.
  internal static var homeEmptyRecent: String { return L10n.tr("Localizable", "Home.Empty.Recent", fallback: "No recent files.") }
  /// No files yet.
  internal static var homeEmptyTitle: String { return L10n.tr("Localizable", "Home.Empty.Title", fallback: "No files yet.") }
  ///  Editor
  internal static var homeHeaderEditor: String { return L10n.tr("Localizable", "Home.Header.Editor", fallback: " Editor") }
  /// HWP
  internal static var homeHeaderHwp: String { return L10n.tr("Localizable", "Home.Header.Hwp", fallback: "HWP") }
  /// Bookmark
  internal static var homeTabBookmark: String { return L10n.tr("Localizable", "Home.Tab.Bookmark", fallback: "Bookmark") }
  /// My File
  internal static var homeTabMyFile: String { return L10n.tr("Localizable", "Home.Tab.MyFile", fallback: "My File") }
  /// Recent
  internal static var homeTabRecent: String { return L10n.tr("Localizable", "Home.Tab.Recent", fallback: "Recent") }
  /// Couldn't import this file. Please try again.
  internal static var importFailed: String { return L10n.tr("Localizable", "Import.Failed", fallback: "Couldn't import this file. Please try again.") }
  /// Import file
  internal static var importFile: String { return L10n.tr("Localizable", "Import.File", fallback: "Import file") }
  /// Import or convert your files to HWP
  internal static var importTitle: String { return L10n.tr("Localizable", "Import.Title", fallback: "Import or convert your files to HWP") }
  /// Only HWP and HWPX files are supported.
  internal static var importUnsupported: String { return L10n.tr("Localizable", "Import.Unsupported", fallback: "Only HWP and HWPX files are supported.") }
  /// Select a file from your device
  internal static var importFileSubtitle: String { return L10n.tr("Localizable", "Import.File.Subtitle", fallback: "Select a file from your device") }
  /// Next
  internal static var introduceNextButton: String { return L10n.tr("Localizable", "Introduce.NextButton", fallback: "Next") }
  /// Start
  internal static var introduceStartButton: String { return L10n.tr("Localizable", "Introduce.StartButton", fallback: "Start") }
  /// Quickly access and view HWP/HWPX anytime
  internal static var introduceStep1Title: String { return L10n.tr("Localizable", "Introduce.Step1.Title", fallback: "Quickly access and view HWP/HWPX anytime") }
  /// Edit and highlight HWP files on your phone
  internal static var introduceStep2Title: String { return L10n.tr("Localizable", "Introduce.Step2.Title", fallback: "Edit and highlight HWP files on your phone") }
  /// Convert PDF or DOC to HWP in a few steps
  internal static var introduceStep3Title: String { return L10n.tr("Localizable", "Introduce.Step3.Title", fallback: "Convert PDF or DOC to HWP in a few steps") }
  /// Next
  internal static var languageApplyButton: String { return L10n.tr("Localizable", "Language.ApplyButton", fallback: "Next") }
  /// Language applied successfully!
  internal static var languageApplySuccess: String { return L10n.tr("Localizable", "Language.ApplySuccess", fallback: "Language applied successfully!") }
  /// Next
  internal static var languageNext: String { return L10n.tr("Localizable", "Language.Next", fallback: "Next") }
  /// Language
  internal static var languageTitle: String { return L10n.tr("Localizable", "Language.Title", fallback: "Language") }
  /// Ads are about to be show...
  internal static var loadDataLoadTitle: String { return L10n.tr("Localizable", "LoadData.LoadTitle", fallback: "Ads are about to be show...") }
  /// Open, edit & convert HWP files
  internal static var loadDataSubTitle: String { return L10n.tr("Localizable", "LoadData.SubTitle", fallback: "Open, edit & convert HWP files") }
  /// Check Connection
  internal static var loadDataNetworkCheckConnection: String { return L10n.tr("Localizable", "LoadData.Network.CheckConnection", fallback: "Check Connection") }
  /// For the best app experience, please enable your Internet connection.
  internal static var loadDataNetworkDescription: String { return L10n.tr("Localizable", "LoadData.Network.Description", fallback: "For the best app experience, please enable your Internet connection.") }
  /// Internet connection lost
  internal static var loadDataNetworkTitle: String { return L10n.tr("Localizable", "LoadData.Network.Title", fallback: "Internet connection lost") }
  /// Use without Internet
  internal static var loadDataNetworkUseWithoutInternet: String { return L10n.tr("Localizable", "LoadData.Network.UseWithoutInternet", fallback: "Use without Internet") }
  /// All File
  internal static var mainTabAllFile: String { return L10n.tr("Localizable", "MainTab.AllFile", fallback: "All File") }
  /// Settings
  internal static var mainTabSettings: String { return L10n.tr("Localizable", "MainTab.Settings", fallback: "Settings") }
  /// Tools
  internal static var mainTabTools: String { return L10n.tr("Localizable", "MainTab.Tools", fallback: "Tools") }
  /// CONTINUE
  internal static var paywallContinue: String { return L10n.tr("Localizable", "Paywall.Continue", fallback: "CONTINUE") }
  /// Cancel anytime. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.
  internal static var paywallTerms: String { return L10n.tr("Localizable", "Paywall.Terms", fallback: "Cancel anytime. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.") }
  /// Go Premium with HWP Pro
  internal static var paywallTitle: String { return L10n.tr("Localizable", "Paywall.Title", fallback: "Go Premium with HWP Pro") }
  /// BASIC
  internal static var paywallColumnBasic: String { return L10n.tr("Localizable", "Paywall.Column.Basic", fallback: "BASIC") }
  /// PRO
  internal static var paywallColumnPro: String { return L10n.tr("Localizable", "Paywall.Column.Pro", fallback: "PRO") }
  /// SUBSCRIBE NOW
  internal static var paywallContinueSubscribe: String { return L10n.tr("Localizable", "Paywall.Continue.Subscribe", fallback: "SUBSCRIBE NOW") }
  /// START FREE TRIAL
  internal static var paywallContinueTrial: String { return L10n.tr("Localizable", "Paywall.Continue.Trial", fallback: "START FREE TRIAL") }
  /// Enjoy an Ad-Free Experience
  internal static var paywallFeatureAdFree: String { return L10n.tr("Localizable", "Paywall.Feature.AdFree", fallback: "Enjoy an Ad-Free Experience") }
  /// Convert PDF or DOC to HWP
  internal static var paywallFeatureConvert: String { return L10n.tr("Localizable", "Paywall.Feature.Convert", fallback: "Convert PDF or DOC to HWP") }
  /// Edit HWP Files with Ease
  internal static var paywallFeatureEdit: String { return L10n.tr("Localizable", "Paywall.Feature.Edit", fallback: "Edit HWP Files with Ease") }
  /// Open & Read HWP/HWPX
  internal static var paywallFeatureOpenRead: String { return L10n.tr("Localizable", "Paywall.Feature.OpenRead", fallback: "Open & Read HWP/HWPX") }
  /// Faster Processing Speed
  internal static var paywallFeaturePrint: String { return L10n.tr("Localizable", "Paywall.Feature.Print", fallback: "Faster Processing Speed") }
  /// Unlock All Premium Features
  internal static var paywallFeatureUnlimited: String { return L10n.tr("Localizable", "Paywall.Feature.Unlimited", fallback: "Unlock All Premium Features") }
  /// %@ per %@. Cancel anytime.
  internal static func paywallNoteNoTrial(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Paywall.Note.NoTrial", String(describing: p1), String(describing: p2), fallback: "%@ per %@. Cancel anytime.")
  }
  /// Free for %@ days, then %@ per %@
  internal static func paywallNoteTrial(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return L10n.tr("Localizable", "Paywall.Note.Trial", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "Free for %@ days, then %@ per %@")
  }
  /// Best Offer
  internal static var paywallOptionBestOffer: String { return L10n.tr("Localizable", "Paywall.Option.BestOffer", fallback: "Best Offer") }
  /// %@ for the first %@
  internal static func paywallOptionIntro(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Paywall.Option.Intro", String(describing: p1), String(describing: p2), fallback: "%@ for the first %@")
  }
  /// %@ / %@
  internal static func paywallOptionPrice(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Paywall.Option.Price", String(describing: p1), String(describing: p2), fallback: "%@ / %@")
  }
  /// Free trial disabled
  internal static var paywallOptionTrialDisabled: String { return L10n.tr("Localizable", "Paywall.Option.TrialDisabled", fallback: "Free trial disabled") }
  /// Free trial enabled
  internal static var paywallOptionTrialEnabled: String { return L10n.tr("Localizable", "Paywall.Option.TrialEnabled", fallback: "Free trial enabled") }
  /// then %@ per %@
  internal static func paywallOptionIntroSubtitle(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "Paywall.Option.Intro.Subtitle", String(describing: p1), String(describing: p2), fallback: "then %@ per %@")
  }
  /// month
  internal static var paywallPeriodMonth: String { return L10n.tr("Localizable", "Paywall.Period.Month", fallback: "month") }
  /// week
  internal static var paywallPeriodWeek: String { return L10n.tr("Localizable", "Paywall.Period.Week", fallback: "week") }
  /// year
  internal static var paywallPeriodYear: String { return L10n.tr("Localizable", "Paywall.Period.Year", fallback: "year") }
  /// Try HWP Pro free for %@ days
  internal static func paywallTitleTrial(_ p1: Any) -> String {
    return L10n.tr("Localizable", "Paywall.Title.Trial", String(describing: p1), fallback: "Try HWP Pro free for %@ days")
  }
  /// Cancel
  internal static var popupCancel: String { return L10n.tr("Localizable", "Popup.Cancel", fallback: "Cancel") }
  /// Delete
  internal static var popupDelete: String { return L10n.tr("Localizable", "Popup.Delete", fallback: "Delete") }
  /// Later
  internal static var popupLater: String { return L10n.tr("Localizable", "Popup.Later", fallback: "Later") }
  /// OK
  internal static var popupOk: String { return L10n.tr("Localizable", "Popup.Ok", fallback: "OK") }
  /// Save
  internal static var popupSave: String { return L10n.tr("Localizable", "Popup.Save", fallback: "Save") }
  /// Try Again
  internal static var popupTryAgain: String { return L10n.tr("Localizable", "Popup.TryAgain", fallback: "Try Again") }
  /// Are you sure you want to delete this file?
  internal static var popupDeleteMessage: String { return L10n.tr("Localizable", "Popup.Delete.Message", fallback: "Are you sure you want to delete this file?") }
  /// Delete File?
  internal static var popupDeleteTitle: String { return L10n.tr("Localizable", "Popup.Delete.Title", fallback: "Delete File?") }
  /// Something went wrong
  internal static var popupErrorTitle: String { return L10n.tr("Localizable", "Popup.Error.Title", fallback: "Something went wrong") }
  /// Exit Now
  internal static var popupExitConfirm: String { return L10n.tr("Localizable", "Popup.Exit.Confirm", fallback: "Exit Now") }
  /// Are you sure you want to exit the app?
  internal static var popupExitMessage: String { return L10n.tr("Localizable", "Popup.Exit.Message", fallback: "Are you sure you want to exit the app?") }
  /// Exit App?
  internal static var popupExitTitle: String { return L10n.tr("Localizable", "Popup.Exit.Title", fallback: "Exit App?") }
  /// Check your network and try again.
  internal static var popupOfflineMessage: String { return L10n.tr("Localizable", "Popup.Offline.Message", fallback: "Check your network and try again.") }
  /// You're Offline
  internal static var popupOfflineTitle: String { return L10n.tr("Localizable", "Popup.Offline.Title", fallback: "You're Offline") }
  /// Do you want to save your changes before leaving?
  internal static var popupSaveChangesMessage: String { return L10n.tr("Localizable", "Popup.SaveChanges.Message", fallback: "Do you want to save your changes before leaving?") }
  /// Save Changes?
  internal static var popupSaveChangesTitle: String { return L10n.tr("Localizable", "Popup.SaveChanges.Title", fallback: "Save Changes?") }
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
  /// Couldn't rename the file. Please try again.
  internal static var renameFailed: String { return L10n.tr("Localizable", "Rename.Failed", fallback: "Couldn't rename the file. Please try again.") }
  /// Enter file name
  internal static var renamePlaceholder: String { return L10n.tr("Localizable", "Rename.Placeholder", fallback: "Enter file name") }
  /// Rename
  internal static var renameTitle: String { return L10n.tr("Localizable", "Rename.Title", fallback: "Rename") }
  /// This name already exists
  internal static var renameErrorExists: String { return L10n.tr("Localizable", "Rename.Error.Exists", fallback: "This name already exists") }
  /// File name contains invalid characters
  internal static var renameErrorInvalid: String { return L10n.tr("Localizable", "Rename.Error.Invalid", fallback: "File name contains invalid characters") }
  /// No result
  internal static var searchNoResult: String { return L10n.tr("Localizable", "Search.NoResult", fallback: "No result") }
  /// Search files...
  internal static var searchPlaceholder: String { return L10n.tr("Localizable", "Search.Placeholder", fallback: "Search files...") }
  /// EU Consent
  internal static var settingsEuConsent: String { return L10n.tr("Localizable", "Settings.EuConsent", fallback: "EU Consent") }
  /// Language
  internal static var settingsLanguage: String { return L10n.tr("Localizable", "Settings.Language", fallback: "Language") }
  /// Manage Subscriptions
  internal static var settingsManageSubscriptions: String { return L10n.tr("Localizable", "Settings.ManageSubscriptions", fallback: "Manage Subscriptions") }
  /// Privacy Policy
  internal static var settingsPrivacyPolicy: String { return L10n.tr("Localizable", "Settings.PrivacyPolicy", fallback: "Privacy Policy") }
  /// Rate app
  internal static var settingsRateApp: String { return L10n.tr("Localizable", "Settings.RateApp", fallback: "Rate app") }
  /// Share app
  internal static var settingsShareApp: String { return L10n.tr("Localizable", "Settings.ShareApp", fallback: "Share app") }
  /// Terms of Use
  internal static var settingsTermsOfUse: String { return L10n.tr("Localizable", "Settings.TermsOfUse", fallback: "Terms of Use") }
  /// Settings
  internal static var settingsTitle: String { return L10n.tr("Localizable", "Settings.Title", fallback: "Settings") }
  /// Unlock all features & remove ads
  internal static var settingsPremiumSubtitle: String { return L10n.tr("Localizable", "Settings.Premium.Subtitle", fallback: "Unlock all features & remove ads") }
  /// Upgrade to Premium
  internal static var settingsPremiumTitle: String { return L10n.tr("Localizable", "Settings.Premium.Title", fallback: "Upgrade to Premium") }
  /// Check out HWP Viewer - the easiest way to open, edit and convert HWP files on iPhone!
  internal static var settingsShareMessage: String { return L10n.tr("Localizable", "Settings.Share.Message", fallback: "Check out HWP Viewer - the easiest way to open, edit and convert HWP files on iPhone!") }
  /// Added to Bookmark
  internal static var toastBookmarkAdded: String { return L10n.tr("Localizable", "Toast.BookmarkAdded", fallback: "Added to Bookmark") }
  /// Removed from Bookmark
  internal static var toastBookmarkRemoved: String { return L10n.tr("Localizable", "Toast.BookmarkRemoved", fallback: "Removed from Bookmark") }
  /// File deleted
  internal static var toastDeleted: String { return L10n.tr("Localizable", "Toast.Deleted", fallback: "File deleted") }
  /// File renamed
  internal static var toastRenamed: String { return L10n.tr("Localizable", "Toast.Renamed", fallback: "File renamed") }
  /// Saved
  internal static var toastSaved: String { return L10n.tr("Localizable", "Toast.Saved", fallback: "Saved") }
  /// Align left
  internal static var toolbarAlignLeft: String { return L10n.tr("Localizable", "Toolbar.AlignLeft", fallback: "Align left") }
  /// Align right
  internal static var toolbarAlignRight: String { return L10n.tr("Localizable", "Toolbar.AlignRight", fallback: "Align right") }
  /// Bold
  internal static var toolbarBold: String { return L10n.tr("Localizable", "Toolbar.Bold", fallback: "Bold") }
  /// Highlight
  internal static var toolbarHighlight: String { return L10n.tr("Localizable", "Toolbar.Highlight", fallback: "Highlight") }
  /// Italic
  internal static var toolbarItalic: String { return L10n.tr("Localizable", "Toolbar.Italic", fallback: "Italic") }
  /// Redo
  internal static var toolbarRedo: String { return L10n.tr("Localizable", "Toolbar.Redo", fallback: "Redo") }
  /// Strike through
  internal static var toolbarStrikethrough: String { return L10n.tr("Localizable", "Toolbar.Strikethrough", fallback: "Strike through") }
  /// Text Color
  internal static var toolbarTextColor: String { return L10n.tr("Localizable", "Toolbar.TextColor", fallback: "Text Color") }
  /// Underline
  internal static var toolbarUnderline: String { return L10n.tr("Localizable", "Toolbar.Underline", fallback: "Underline") }
  /// Undo
  internal static var toolbarUndo: String { return L10n.tr("Localizable", "Toolbar.Undo", fallback: "Undo") }
  /// Import from Files
  internal static var toolsImportFromFiles: String { return L10n.tr("Localizable", "Tools.ImportFromFiles", fallback: "Import from Files") }
  /// Select File
  internal static var toolsSelectFile: String { return L10n.tr("Localizable", "Tools.SelectFile", fallback: "Select File") }
  /// Tools
  internal static var toolsTitle: String { return L10n.tr("Localizable", "Tools.Title", fallback: "Tools") }
  /// No files found. Import a file to get started.
  internal static var toolsSelectFileEmpty: String { return L10n.tr("Localizable", "Tools.SelectFile.Empty", fallback: "No files found. Import a file to get started.") }
  /// Edit HWP
  internal static var viewerEditHwp: String { return L10n.tr("Localizable", "Viewer.EditHwp", fallback: "Edit HWP") }
  /// The file is invalid or corrupted and cannot be opened.
  internal static var viewerInvalidFile: String { return L10n.tr("Localizable", "Viewer.InvalidFile", fallback: "The file is invalid or corrupted and cannot be opened.") }
  /// Preparing fonts...
  internal static var viewerLoadingFonts: String { return L10n.tr("Localizable", "Viewer.LoadingFonts", fallback: "Preparing fonts...") }
  /// Save
  internal static var viewerSave: String { return L10n.tr("Localizable", "Viewer.Save", fallback: "Save") }
  /// Couldn't save the file. Please try again.
  internal static var viewerSaveFailed: String { return L10n.tr("Localizable", "Viewer.SaveFailed", fallback: "Couldn't save the file. Please try again.") }
  /// Press and hold to select text
  internal static var viewerSelectionHint: String { return L10n.tr("Localizable", "Viewer.SelectionHint", fallback: "Press and hold to select text") }
  /// Select the text you want to edit first
  internal static var viewerSelectionRequired: String { return L10n.tr("Localizable", "Viewer.SelectionRequired", fallback: "Select the text you want to edit first") }
  /// Copy
  internal static var viewerMenuCopy: String { return L10n.tr("Localizable", "Viewer.Menu.Copy", fallback: "Copy") }
  /// Cut
  internal static var viewerMenuCut: String { return L10n.tr("Localizable", "Viewer.Menu.Cut", fallback: "Cut") }
  /// Delete
  internal static var viewerMenuDelete: String { return L10n.tr("Localizable", "Viewer.Menu.Delete", fallback: "Delete") }
  /// Paste
  internal static var viewerMenuPaste: String { return L10n.tr("Localizable", "Viewer.Menu.Paste", fallback: "Paste") }
  /// Search in document
  internal static var viewerSearchPlaceholder: String { return L10n.tr("Localizable", "Viewer.Search.Placeholder", fallback: "Search in document") }
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = NSCustomLocalizedString(key, table, value)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
