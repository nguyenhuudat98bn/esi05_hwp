//
//  OcrInkSampler.swift
//  HWPViewer
//
//  Colour reads on an OCR page (a downscaled RGBA copy): the ink of a recognised line, for the text
//  colour in the HWP, and the paper / cell colour around it, for painting the line out of the background.
//

import UIKit

/// Reads ink colours from a downscaled RGBA copy of the page.
final class OcrInkSampler {
    private let width: Int
    private let height: Int
    private let pixels: [UInt8]

    init?(image: CGImage, maxSide: Int = 1200) {
        let factor = min(1, Double(maxSide) / Double(max(image.width, image.height)))
        let w = max(1, Int(Double(image.width) * factor))
        let h = max(1, Int(Double(image.height) * factor))
        var buffer = [UInt8](repeating: 255, count: w * h * 4)
        let drawn: Bool = buffer.withUnsafeMutableBytes { raw in
            guard let context = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                          bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }
        width = w
        height = h
        pixels = buffer
    }

    /// Pixel at a normalised point (top-left origin), nil outside the image.
    func rgb(at point: CGPoint) -> (Int, Int, Int)? {
        let x = Int(point.x * CGFloat(width)), y = Int(point.y * CGFloat(height))
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let i = (y * width + x) * 4
        return (Int(pixels[i]), Int(pixels[i + 1]), Int(pixels[i + 2]))
    }

    /// "#rrggbb" of the text's ink in `box` (normalised, top-left); nil for text darker than its paper
    /// and not coloured (black / gray / a blurred photo of black text: the default black reads best).
    /// The paper is read just outside the box, the ink is the 15% of pixels in the box farthest from it,
    /// so coloured text, white text on a dark band and dark-mode screenshots keep a colour that shows.
    func inkHex(in box: CGRect) -> String? {
        let x0 = max(0, Int(box.minX * CGFloat(width))), x1 = min(width, Int(box.maxX * CGFloat(width)))
        let y0 = max(0, Int(box.minY * CGFloat(height))), y1 = min(height, Int(box.maxY * CGFloat(height)))
        guard x1 > x0, y1 > y0, let paper = ringMedian(around: box, margin: box.height * 0.3) else { return nil }
        var rs: [Int] = [], gs: [Int] = [], bs: [Int] = [], distances: [Int] = []
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                let r = Int(pixels[i]), g = Int(pixels[i + 1]), b = Int(pixels[i + 2])
                rs.append(r); gs.append(g); bs.append(b)
                distances.append(abs(r - paper.r) + abs(g - paper.g) + abs(b - paper.b))
            }
        }
        let ink = rs.indices.sorted { distances[$0] > distances[$1] }.prefix(max(1, rs.count * 15 / 100))
        let n = ink.count
        let r = ink.reduce(0) { $0 + rs[$1] } / n, g = ink.reduce(0) { $0 + gs[$1] } / n, b = ink.reduce(0) { $0 + bs[$1] } / n
        guard abs(r - paper.r) + abs(g - paper.g) + abs(b - paper.b) >= 90 else { return nil } // ink not told apart
        let coloured = max(r, g, b) - min(r, g, b) >= 60
        func luminance(_ r: Int, _ g: Int, _ b: Int) -> Int { (r * 299 + g * 587 + b * 114) / 1000 }
        guard coloured || luminance(r, g, b) > luminance(paper.r, paper.g, paper.b) else { return nil }
        return String(format: "#%02x%02x%02x", r, g, b)
    }

    /// Median colour of a thin ring `margin` outside `box` (normalised, top-left): the paper / cell colour
    /// behind a line. Nil when the ring lies outside the image.
    func ringMedian(around box: CGRect, margin: CGFloat) -> (r: Int, g: Int, b: Int)? {
        let ring = box.insetBy(dx: -margin, dy: -margin)
        var samples: [(Int, Int, Int)] = []
        let steps = 24
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            for point in [CGPoint(x: ring.minX + t * ring.width, y: ring.minY), CGPoint(x: ring.minX + t * ring.width, y: ring.maxY),
                          CGPoint(x: ring.minX, y: ring.minY + t * ring.height), CGPoint(x: ring.maxX, y: ring.minY + t * ring.height)] {
                if let rgb = rgb(at: point) { samples.append(rgb) }
            }
        }
        guard !samples.isEmpty else { return nil }
        func median(_ values: [Int]) -> Int { values.sorted()[values.count / 2] }
        return (median(samples.map(\.0)), median(samples.map(\.1)), median(samples.map(\.2)))
    }
}

extension OcrInkSampler {
    /// The paper / cell colour behind `box` (a ring `margin` outside it). Kept tight so a shaded table
    /// cell is sampled, not the page around it.
    func paperColor(around box: CGRect, margin: CGFloat) -> UIColor {
        guard let c = ringMedian(around: box, margin: margin) else { return .white }
        return UIColor(red: CGFloat(c.r) / 255, green: CGFloat(c.g) / 255, blue: CGFloat(c.b) / 255, alpha: 1)
    }
}
