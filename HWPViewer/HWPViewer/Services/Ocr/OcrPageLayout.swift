//
//  OcrPageLayout.swift
//  HWPViewer
//
//  Turns recognised lines (normalised image boxes) into the engine's OCR JSON: paper size from the
//  image aspect (A4 portrait / landscape, else the image's own proportion), each line placed at the
//  same spot on the paper in points, with a font size estimated from the box and snapped to the
//  sizes used on the page (so one paragraph does not jump between 11.8 / 12.6 / 13.1pt), a baseline,
//  and the ink colour when it is clearly not black. The engine groups lines into text boxes.
//

import UIKit

struct OcrPagePlacement {
    /// Paper size (pt).
    let paper: CGSize
    /// Where the image sits on the paper (pt): scaled to fit and centred.
    let imageRect: CGRect
}

enum OcrPageLayout {
    static let a4 = CGSize(width: 595.28, height: 841.89)
    /// Korean font every HWP reader knows; on iOS the renderer falls back to Apple SD Gothic Neo / Noto Sans KR.
    static let fontFamily = "맑은 고딕"

    static func placement(forImageSize size: CGSize) -> OcrPagePlacement {
        let aspect = size.height / max(size.width, 1)
        let paper: CGSize
        switch aspect {
        case 1.2...1.65: paper = a4
        case 0.6...0.83: paper = CGSize(width: a4.height, height: a4.width)
        default: paper = CGSize(width: a4.width, height: min(max(a4.width * aspect, 200), 2400))
        }
        let scale = min(paper.width / size.width, paper.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        let origin = CGPoint(x: (paper.width - fitted.width) / 2, y: (paper.height - fitted.height) / 2)
        return OcrPagePlacement(paper: paper, imageRect: CGRect(origin: origin, size: fitted))
    }

    /// Engine JSON entries (`text`, `x`, `y`, `w`, `baseline`, `size`, optional `color`) for one page.
    static func lines(_ lines: [OcrLine], placement: OcrPagePlacement, colors: OcrInkSampler?) -> [[String: Any]] {
        let rect = placement.imageRect
        let boxes = lines.map { line in
            CGRect(x: rect.minX + line.box.minX * rect.width, y: rect.minY + line.box.minY * rect.height,
                   width: line.box.width * rect.width, height: line.box.height * rect.height)
        }
        // Snap to the page's sizes, but never past what fits the line's box (+4%).
        let sizes = zip(snap(zip(lines, boxes).map { estimateSize(text: $0.text, box: $1) }), zip(lines, boxes)).map { size, pair in
            let em = emWidth(of: pair.0.text)
            return em > 0 ? max(4, min(size, pair.1.width * 1.04 / em)) : size
        }
        let inks = unifyColors(lines.map { colors?.inkHex(in: $0.box) })
        return lines.indices.map { index in
            let box = boxes[index]
            let size = sizes[index]
            var entry: [String: Any] = [
                "text": lines[index].text,
                "x": round2(box.minX), "y": round2(box.minY), "w": round2(box.width),
                "baseline": round2(box.maxY - size * 0.18),
                "size": size,
            ]
            if let hex = inks[index] { entry["color"] = hex }
            return entry
        }
    }

    // MARK: - Font size

    /// Advance widths (em) the engine lays out "맑은 고딕" with, measured from its SVG output
    /// (Hangul 0.95, A–Z 0.584, a–z 0.476, digits 0.525, space 0.444). The text must fit these, not
    /// iOS font metrics, or long lines run past the right edge of the page.
    static func emWidth(of text: String) -> CGFloat {
        text.unicodeScalars.reduce(0) { sum, scalar in
            let v = scalar.value
            switch v {
            case 0x20: return sum + 0.444
            case 0x41...0x5A: return sum + 0.584
            case 0x61...0x7A: return sum + 0.476
            case 0x30...0x39: return sum + 0.525
            case 0x21...0x7E: return sum + 0.42            // ASCII punctuation
            case 0x1100...0x11FF, 0x2000...0x33FF, 0x3400...0x9FFF, 0xAC00...0xD7AF, 0xF900...0xFAFF, 0xFF00...0xFFEF:
                return sum + 0.95                             // Hangul, CJK, full-width symbols (※ ① ○ …)
            default: return sum + 0.6
            }
        }
    }

    /// Height gives a first guess (Vision boxes are ~1.18 × the font size for Korean); for lines with a
    /// few characters the text's width in engine metrics refines it, within −25% / +20%.
    static func estimateSize(text: String, box: CGRect) -> CGFloat {
        let byHeight = box.height / 1.18
        let em = emWidth(of: text)
        guard text.count >= 4, byHeight > 2, em > 0 else { return max(byHeight, 4) }
        let byWidth = box.width / em
        return min(max(byWidth, byHeight * 0.75), byHeight * 1.2)
    }

    /// Groups sizes that are within 10% of each other and gives each group its median, rounded to 0.5pt.
    static func snap(_ sizes: [CGFloat]) -> [CGFloat] {
        let order = sizes.indices.sorted { sizes[$0] < sizes[$1] }
        var result = sizes
        var group: [Int] = []
        func flush() {
            guard !group.isEmpty else { return }
            let values = group.map { sizes[$0] }.sorted()
            let median = (values[values.count / 2] * 2).rounded() / 2
            group.forEach { result[$0] = max(median, 4) }
            group.removeAll()
        }
        for index in order {
            if let first = group.first, sizes[index] > sizes[first] * 1.1 { flush() }
            group.append(index)
        }
        flush()
        return result
    }

    /// Ink colours close to one already used on the page reuse it (sum of channel differences ≤ 48), so a
    /// paragraph of white or blue text is one colour — one char shape in the file — not a dozen near-equal ones.
    static func unifyColors(_ hexes: [String?]) -> [String?] {
        var palette: [(hex: String, rgb: [Int])] = []
        return hexes.map { hex in
            guard let hex, let value = Int(hex.dropFirst(), radix: 16) else { return nil }
            let rgb = [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
            if let near = palette.first(where: { zip($0.rgb, rgb).reduce(0) { $0 + abs($1.0 - $1.1) } <= 48 }) { return near.hex }
            palette.append((hex, rgb))
            return hex
        }
    }

    private static func round2(_ value: CGFloat) -> Double { (Double(value) * 100).rounded() / 100 }
}
