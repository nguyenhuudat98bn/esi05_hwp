//
//  DocumentRectangleDetector.swift
//  HWPViewer
//
//  Finds the sheet of paper in a camera frame / photo (Vision rectangle detection) and flattens it
//  (Core Image perspective correction), so OCR sees a straight page.
//

import UIKit
import Vision
import CoreImage

enum DocumentRectangleDetector {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func makeRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.6
        request.minimumSize = 0.25
        request.minimumAspectRatio = 0.3
        request.quadratureTolerance = 25
        return request
    }

    /// Largest page-like quadrilateral in `image`, normalised (Vision coordinates, origin bottom-left).
    static func detect(in image: CGImage) -> VNRectangleObservation? {
        let request = makeRequest()
        try? VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        return request.results?.first
    }

    /// The page cut out of `image` and squared up; the whole image when no page is found or the page
    /// covers less than `minimumCoverage` of the picture (a table inside a scan is not a page).
    static func flattenedPage(from image: CGImage, minimumCoverage: CGFloat = 0.2) -> CGImage {
        guard let quad = detect(in: image), area(of: quad) >= minimumCoverage else { return image }
        let input = CIImage(cgImage: image)
        let size = input.extent.size
        func point(_ p: CGPoint) -> CIVector { CIVector(x: p.x * size.width, y: p.y * size.height) }
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return image }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(point(quad.topLeft), forKey: "inputTopLeft")
        filter.setValue(point(quad.topRight), forKey: "inputTopRight")
        filter.setValue(point(quad.bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(point(quad.bottomRight), forKey: "inputBottomRight")
        guard let output = filter.outputImage else { return image }
        // Perspective correction cannot know the sheet's real proportions; take them from the edge
        // lengths and snap to A4 (portrait / landscape) when close — most documents here are A4.
        let width = output.extent.width
        let target = pageAspect(quad, imageSize: size)
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 1, y: width * target / max(output.extent.height, 1)))
        guard let flat = context.createCGImage(scaled, from: scaled.extent.integral) else { return image }
        return flat
    }

    /// Height / width of the page from the quad's edges, snapped to √2 or 1/√2 when within ~15%.
    static func pageAspect(_ quad: VNRectangleObservation, imageSize size: CGSize) -> CGFloat {
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot((a.x - b.x) * size.width, (a.y - b.y) * size.height)
        }
        let width = (distance(quad.topLeft, quad.topRight) + distance(quad.bottomLeft, quad.bottomRight)) / 2
        let height = (distance(quad.topLeft, quad.bottomLeft) + distance(quad.topRight, quad.bottomRight)) / 2
        let ratio = height / max(width, 1)
        switch ratio {
        case 1.2...1.65: return sqrt(2)
        case 0.6...0.83: return 1 / sqrt(2)
        default: return ratio
        }
    }

    /// Normalised area of the quad (shoelace).
    static func area(of quad: VNRectangleObservation) -> CGFloat {
        let p = [quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft]
        var sum: CGFloat = 0
        for i in 0..<4 {
            let a = p[i], b = p[(i + 1) % 4]
            sum += a.x * b.y - b.x * a.y
        }
        return abs(sum) / 2
    }
}
