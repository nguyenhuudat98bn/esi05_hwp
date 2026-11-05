//
//  OcrToHwpService.swift
//  HWPViewer
//
//  OCR to HWP: page image → Vision text (Korean + English, on device) → layout JSON (lines at their
//  paper position, snapped font sizes, ink colours) + cleaned background → engine
//  `RhwpDocument.importOCR` → HWP bytes. The engine turns each block of lines into a text box at the
//  same spot, so the page keeps its frame and the text is editable. Saving happens after the user
//  names the file.
//

import UIKit
import HwpEditorKit
import SPNComponent

/// A converted page waiting for its file name.
struct OcrConversion {
    let data: Data
    let pageCount: Int
    let lineCount: Int
}

enum OcrError: LocalizedError {
    case unreadableImage
    case noText

    var errorDescription: String? { L10n.ocrErrorMessage }
}

final class OcrToHwpService {
    static let shared = OcrToHwpService()

    private init() {}

    /// `image` is already the page (camera captures are flattened by the camera screen).
    func convert(_ image: UIImage) async throws -> OcrConversion {
        try await HwpEngine.prepare()
        return try await Task.detached(priority: .userInitiated) {
            guard let picture = image.uprightCGImage() else { throw OcrError.unreadableImage }
            // Sideways / upside-down pages come back turned so the text reads left → right.
            let (page, lines) = try OcrTextRecognizer.recognizeUpright(picture)
            guard !lines.isEmpty else { throw OcrError.noText }
            try Task.checkCancellation()

            let placement = OcrPageLayout.placement(forImageSize: CGSize(width: page.width, height: page.height))
            let entries = OcrPageLayout.lines(lines, placement: placement, colors: OcrInkSampler(image: page))
            let background = OcrBackgroundCleaner.cleanedPage(page, erasing: lines)
            defer { if let background { try? FileManager.default.removeItem(at: background) } }

            var pageJSON: [String: Any] = ["lines": entries]
            if let background {
                let r = placement.imageRect
                pageJSON["image"] = ["path": background.path, "x": r.minX, "y": r.minY, "w": r.width, "h": r.height]
            }
            let json: [String: Any] = [
                "pageWidth": placement.paper.width, "pageHeight": placement.paper.height,
                "font": OcrPageLayout.fontFamily, "pages": [pageJSON],
            ]
            let body = try JSONSerialization.data(withJSONObject: json)
            try Task.checkCancellation()
            let document = try RhwpDocument.importOCR(json: body)
            let data = try document.exportHWP()
            logger("[OCR] \(lines.count) lines, page \(Int(placement.paper.width))×\(Int(placement.paper.height))pt → \(data.count) bytes")
            return OcrConversion(data: data, pageCount: document.pageCount, lineCount: lines.count)
        }.value
    }

    /// Writes the converted document as `<name>.hwp` in Documents.
    func save(_ conversion: OcrConversion, named name: String) throws -> DocumentOutput {
        let destination = FileStore.shared.uniqueURL(for: "\(name).hwp")
        try conversion.data.write(to: destination, options: .atomic)
        FileStore.shared.notifyChanged()
        return DocumentOutput(url: destination, size: Int64(conversion.data.count), pageCount: conversion.pageCount)
    }
}
