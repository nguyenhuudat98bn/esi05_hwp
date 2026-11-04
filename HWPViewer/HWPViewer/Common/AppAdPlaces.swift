//
//  AppAdPlaces.swift
//  HWPViewer
//
//  Screen-level ad places (spec §3). Same value is used for native slot + interstitial.
//

import SPNComponent

extension SPNAdPlace {
    static let viewer: SPNAdPlace = "viewer_screen"
    static let importSheet: SPNAdPlace = "import_sheet"
    /// "More" sheet of a file (Rename / Share / Print / Delete), native at the bottom.
    static let fileActionSheet: SPNAdPlace = "file_action_sheet"
    static let tools: SPNAdPlace = "tools_screen"
    static let selectFile: SPNAdPlace = "select_file_screen"
    static let search: SPNAdPlace = "search_screen"
    static let convert: SPNAdPlace = "convert_screen"
    /// Merge / Split HWP screens (POC). No remote ad config yet, so nothing is shown there.
    static let mergeSplit: SPNAdPlace = "merge_split_screen"
    /// OCR to HWP (preview / result / error; interstitial before converting for free users).
    static let ocr: SPNAdPlace = "ocr_screen"
    /// Native inline rows (2nd item of a file list).
    static let homeListInline: SPNAdPlace = "home_list_inline"
    static let searchListInline: SPNAdPlace = "search_list_inline"
    static let selectFileListInline: SPNAdPlace = "select_file_list_inline"
}
