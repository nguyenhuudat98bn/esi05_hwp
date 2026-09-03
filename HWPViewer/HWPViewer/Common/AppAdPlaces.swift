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
    static let tools: SPNAdPlace = "tools_screen"
    static let search: SPNAdPlace = "search_screen"
    static let convert: SPNAdPlace = "convert_screen"
}
