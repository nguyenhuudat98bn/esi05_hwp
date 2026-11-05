//
//  OcrTextRecognizer.swift
//  HWPViewer
//
//  On-device text recognition (Apple Vision, accurate, Korean + English). Returns one entry per
//  recognised line with its box in normalised image coordinates (origin top-left, 0…1).
//  Pages photographed sideways or upside down are turned first, so the text always reads left → right.
//  Nothing leaves the device.
//

import UIKit
import Vision

struct OcrLine {
    let text: String
    /// Normalised box, origin top-left.
    let box: CGRect
    let confidence: Float
    /// Reading direction on the image, in quarter turns: 0 left → right, 90 bottom → top,
    /// -90 top → bottom, 180 upside down.
    let angle: Int
}

enum OcrTextRecognizer {
    /// Recognition languages, Korean first (the app's documents are mostly Korean).
    static let languages = ["ko-KR", "en-US"]

    /// Whether Vision on this device reads Korean (accurate revision 3, iOS 16+). The app still runs
    /// on iOS 15, where `ko-KR` is missing and Hangul would come out as Latin noise — the Tools tab
    /// hides OCR there.
    static let supportsKorean: Bool = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        return ((try? request.supportedRecognitionLanguages()) ?? []).contains("ko-KR")
    }()

    /// The page turned so most of its text reads left → right, with its upright lines. Lines in another
    /// direction (a sideways label in a table) are left out: they stay in the background picture.
    static func recognizeUpright(_ image: CGImage) throws -> (page: CGImage, lines: [OcrLine]) {
        var page = image
        var lines = try recognize(page)
        let turn = dominantAngle(of: lines)
        if turn != 0, let turned = page.rotated(clockwiseDegrees: turn) {
            page = turned
            lines = try recognize(page)
        }
        return (page, lines.filter { $0.angle == 0 })
    }

    static func recognize(_ image: CGImage) throws -> [OcrLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        request.recognitionLanguages = languages.filter { supported.isEmpty || supported.contains($0) }
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        let size = CGSize(width: image.width, height: image.height)
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            // Short, unsure reads are usually logos / stamps / marks: leave them in the background image.
            if candidate.confidence < 0.5 && text.count <= 4 { return nil }
            let b = observation.boundingBox // origin bottom-left
            return OcrLine(text: text, box: CGRect(x: b.minX, y: 1 - b.maxY, width: b.width, height: b.height),
                           confidence: candidate.confidence, angle: readingAngle(of: candidate, imageSize: size))
        }
    }

    /// Direction of the line's top edge (its quad from Vision), rounded to a quarter turn.
    private static func readingAngle(of candidate: VNRecognizedText, imageSize: CGSize) -> Int {
        let range = candidate.string.startIndex..<candidate.string.endIndex
        guard let quad = try? candidate.boundingBox(for: range) else { return 0 }
        let dx = (quad.topRight.x - quad.topLeft.x) * imageSize.width
        let dy = (quad.topRight.y - quad.topLeft.y) * imageSize.height // y up
        let quarter = Int((atan2(dy, dx) * 180 / .pi / 90).rounded()) * 90
        return quarter == -180 ? 180 : quarter
    }

    /// Reading direction of most of the text (weighted by characters).
    private static func dominantAngle(of lines: [OcrLine]) -> Int {
        var weight: [Int: Int] = [:]
        for line in lines { weight[line.angle, default: 0] += line.text.count }
        return weight.max { $0.value < $1.value }?.key ?? 0
    }
}

extension CGImage {
    /// The image turned clockwise by 90, -90 (counter-clockwise) or 180 degrees.
    func rotated(clockwiseDegrees degrees: Int) -> CGImage? {
        let w = CGFloat(width), h = CGFloat(height)
        let quarter = degrees == 90 || degrees == -90
        let size = quarter ? CGSize(width: h, height: w) : CGSize(width: w, height: h)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let source = UIImage(cgImage: self)
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let cg = renderer.cgContext
            switch degrees {
            case 90: cg.translateBy(x: h, y: 0); cg.rotate(by: .pi / 2)       // (x, y) → (h − y, x)
            case -90: cg.translateBy(x: 0, y: w); cg.rotate(by: -.pi / 2)     // (x, y) → (y, w − x)
            default: cg.translateBy(x: w, y: h); cg.rotate(by: .pi)           // (x, y) → (w − x, h − y)
            }
            source.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
        }.cgImage
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
