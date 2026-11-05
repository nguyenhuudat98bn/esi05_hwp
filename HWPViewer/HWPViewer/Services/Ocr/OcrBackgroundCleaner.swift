//
//  OcrBackgroundCleaner.swift
//  HWPViewer
//
//  Background layer of an OCR page: the scan whitened with Core Image's document enhancer, with every
//  recognised line painted over in the colour around it — so table lines, boxes, logos and pictures
//  stay behind the editable text while the recognised text is not shown twice. Saved as a JPEG for
//  the engine to place "behind text" on the page.
//

import UIKit
import CoreImage

enum OcrBackgroundCleaner {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// JPEG file of the cleaned page (temporary directory), or nil when the image cannot be processed.
    static func cleanedPage(_ image: CGImage, erasing lines: [OcrLine], maxSide: CGFloat = 1600) -> URL? {
        var input = CIImage(cgImage: image)
        let factor = min(1, maxSide / max(input.extent.width, input.extent.height))
        if factor < 1 {
            input = input.transformed(by: CGAffineTransform(scaleX: factor, y: factor))
        }
        if let enhancer = CIFilter(name: "CIDocumentEnhancer") {
            enhancer.setValue(input, forKey: kCIInputImageKey)
            enhancer.setValue(1.0, forKey: "inputAmount")
            if let output = enhancer.outputImage { input = output.cropped(to: input.extent) }
        }
        guard let enhanced = context.createCGImage(input, from: input.extent) else { return nil }

        let size = CGSize(width: enhanced.width, height: enhanced.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let sampler = OcrInkSampler(image: enhanced, maxSide: 800)
        let cleaned = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            UIImage(cgImage: enhanced).draw(in: CGRect(origin: .zero, size: size))
            let cg = renderer.cgContext
            for line in lines {
                // Grow the box a little: Vision boxes hug the glyphs, anti-aliased edges sit just outside.
                let pad = line.box.height * 0.18
                let box = line.box.insetBy(dx: -pad * 0.5, dy: -pad)
                cg.setFillColor((sampler?.paperColor(around: box, margin: line.box.height * 0.08) ?? .white).cgColor)
                cg.fill(CGRect(x: box.minX * size.width, y: box.minY * size.height,
                               width: box.width * size.width, height: box.height * size.height))
            }
        }
        guard let data = cleaned.jpegData(compressionQuality: 0.7) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ocr-bg-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
