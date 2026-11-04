//
//  OcrTextRecognizer.swift
//  HWPViewer
//
//  On-device text recognition (Apple Vision, accurate, Korean + English). Returns one entry per
//  recognised line with its box in normalised image coordinates (origin top-left, 0…1).
//  Nothing leaves the device.
//

import UIKit
import Vision

struct OcrLine {
    let text: String
    /// Normalised box, origin top-left.
    let box: CGRect
    let confidence: Float
}

enum OcrTextRecognizer {
    /// Recognition languages, Korean first (the app's documents are mostly Korean).
    static let languages = ["ko-KR", "en-US"]

    static func recognize(_ image: CGImage) throws -> [OcrLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        request.recognitionLanguages = languages.filter { supported.isEmpty || supported.contains($0) }
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            // Short, unsure reads are usually logos / stamps / marks: leave them in the background image.
            if candidate.confidence < 0.5 && text.count <= 4 { return nil }
            let b = observation.boundingBox // origin bottom-left
            return OcrLine(text: text, box: CGRect(x: b.minX, y: 1 - b.maxY, width: b.width, height: b.height),
                           confidence: candidate.confidence)
        }
    }
}

extension UIImage {
    /// Pixels drawn upright (camera / Photos images carry an EXIF orientation), at most `maxSide` px.
    func uprightCGImage(maxSide: CGFloat = 3000) -> CGImage? {
        let longest = max(size.width * scale, size.height * scale)
        let factor = min(1, maxSide / max(longest, 1))
        let target = CGSize(width: (size.width * scale * factor).rounded(), height: (size.height * scale * factor).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: target))
            draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.cgImage
    }
}
