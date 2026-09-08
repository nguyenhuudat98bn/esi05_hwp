//
//  FileItem.swift
//  HWPViewer
//
//  A document stored in the app's Documents folder (HWP/HWPX plus PDF/DOC sources for conversion).
//

import Foundation
import UIKit
import UniformTypeIdentifiers

enum FileKind: String, CaseIterable {
    case hwp, hwpx, pdf, doc, docx

    init?(url: URL) {
        self.init(rawValue: url.pathExtension.lowercased())
    }

    var isHwp: Bool { self == .hwp || self == .hwpx }
    var isDoc: Bool { self == .doc || self == .docx }

    /// Extensions grouped by the "file family" used in Tools → Select File.
    static let hwpExtensions: Set<String> = ["hwp", "hwpx"]
    static let pdfExtensions: Set<String> = ["pdf"]
    static let docExtensions: Set<String> = ["doc", "docx"]

    var utType: UTType? {
        switch self {
        case .hwp: return UTType("com.spn.hwpviewer.hwp") ?? UTType(filenameExtension: "hwp")
        case .hwpx: return UTType("com.spn.hwpviewer.hwpx") ?? UTType(filenameExtension: "hwpx")
        case .pdf: return .pdf
        case .doc: return UTType("com.microsoft.word.doc") ?? UTType(filenameExtension: "doc")
        case .docx: return UTType("org.openxmlformats.wordprocessingml.document") ?? UTType(filenameExtension: "docx")
        }
    }
}

/// Family used by pickers and the Tools flow.
enum FileFamily {
    case hwp, pdf, doc

    var extensions: Set<String> {
        switch self {
        case .hwp: return FileKind.hwpExtensions
        case .pdf: return FileKind.pdfExtensions
        case .doc: return FileKind.docExtensions
        }
    }

    var utTypes: [UTType] {
        var types = extensions.compactMap { FileKind(rawValue: $0)?.utType }
        if self == .hwp {
            // HWP has no system-wide UTI, only the one this app exports. A .hwp that reached the
            // device from iCloud/Drive/a download is typed `public.data` or a `dyn.*` placeholder
            // instead, which our identifiers don't match — the picker then greys the file out and
            // the user cannot import at all. Accept any file here; `importFile(allowed:)` still
            // rejects everything that is not .hwp/.hwpx.
            types.append(.data)
        }
        return types
    }
}

struct FileItem: Identifiable, Equatable {
    var url: URL
    var name: String
    var kind: FileKind
    var size: Int64
    var modifiedAt: Date
    var lastOpenedAt: Date?
    var isBookmarked: Bool

    var id: String { url.lastPathComponent }
    /// Name without extension (rename dialog, convert output).
    var displayName: String { url.deletingPathExtension().lastPathComponent }

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var dateText: String {
        Self.dateFormatter.string(from: modifiedAt)
    }

    /// "05/28/2026 12:00 · 145 MB"
    var metaText: String { "\(dateText) · \(sizeText)" }

    /// Locale-aware date + 24h time (a fixed "MM/dd/yyyy" reads wrong outside the US).
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMdd HH:mm")
        return formatter
    }()

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url && lhs.size == rhs.size && lhs.modifiedAt == rhs.modifiedAt
            && lhs.lastOpenedAt == rhs.lastOpenedAt && lhs.isBookmarked == rhs.isBookmarked
    }
}

// MARK: - Bookmark icon

extension FileItem {
    /// Bookmark glyph (Figma file row): enabled = orange filled vector drawn as-is,
    /// disabled = outline template tinted by the caller.
    static func bookmarkIcon(filled: Bool) -> UIImage {
        filled
            ? Asset.Assets.App.icBookmarkFilled.image.withRenderingMode(.alwaysOriginal)
            : Asset.Assets.App.icBookmarkOutline.image.withRenderingMode(.alwaysTemplate)
    }
}
