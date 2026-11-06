//
//  AppAdPlaces.swift
//  HWPViewer
//
//  Screen-level ad places (spec §3). Same value is used for native slot + interstitial.
//

import SPNComponent

extension SPNAdPlace {
    static let viewer: SPNAdPlace = "viewer_screen"
    /// Native "page" after the last page of a document in the viewer (np12 `view_last_page`).
    static let viewLastPage: SPNAdPlace = "view_last_page"
    static let importSheet: SPNAdPlace = "import_sheet"
    /// "More" sheet of a file (Rename / Share / Print / Delete), native at the bottom.
    static let fileActionSheet: SPNAdPlace = "file_action_sheet"
    static let tools: SPNAdPlace = "tools_screen"
    static let selectFile: SPNAdPlace = "select_file_screen"
    static let search: SPNAdPlace = "search_screen"
    static let convert: SPNAdPlace = "convert_screen"
    /// Merge / Split HWP screens: interstitial on back + banner (native: per screen, below).
    static let mergeSplit: SPNAdPlace = "merge_split_screen"
    /// OCR to HWP (preview / result / error; interstitial before converting for free users).
    static let ocr: SPNAdPlace = "ocr_screen"
    /// Native at the bottom of the Merge / Split / OCR screens, one remote entry per screen
    /// (`banner_native_places`). Their interstitial / banner stay on `mergeSplit` / `ocr`.
    static let mergeSelectFile: SPNAdPlace = "merge_select_file_screen"
    static let mergeFiles: SPNAdPlace = "merge_files_screen"
    static let mergeResult: SPNAdPlace = "merge_result_screen"
    static let splitSelectFile: SPNAdPlace = "split_select_file_screen"
    static let splitPages: SPNAdPlace = "split_pages_screen"
    static let splitResult: SPNAdPlace = "split_result_screen"
    static let ocrPreview: SPNAdPlace = "ocr_preview_screen"
    static let ocrResult: SPNAdPlace = "ocr_result_screen"
    /// Interstitial when the user switches tab (pill tab bar), one per destination tab
    /// (`interstitial_advertiser.places`). Spacing / caps: `appconfigs.time_interval_show_ad`,
    /// `max_interstitial_per_session`, `max_interstitial_per_day`.
    static let tabHome: SPNAdPlace = "tab_home"
    static let tabTools: SPNAdPlace = "tab_tools"
    static let tabSettings: SPNAdPlace = "tab_settings"
    /// Native inline rows (2nd item of a file list).
    static let homeListInline: SPNAdPlace = "home_list_inline"
    static let searchListInline: SPNAdPlace = "search_list_inline"
    static let selectFileListInline: SPNAdPlace = "select_file_list_inline"
}
