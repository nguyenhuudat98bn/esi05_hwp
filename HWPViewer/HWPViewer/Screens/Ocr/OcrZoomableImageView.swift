//
//  OcrZoomableImageView.swift
//  HWPViewer
//
//  OCR preview page with pinch-to-zoom (ESI05-54): at 1× the page fills the width, top-aligned
//  (shrunk to fit when the screen is short) as in Figma 6985:111076; pinching zooms around the point
//  between the fingers up to 4×, a double tap toggles 1× ↔ 2.5× at the tapped spot.
//

import UIKit

final class OcrZoomableImageView: UIScrollView, UIScrollViewDelegate {
    let imageView = UIImageView()
    private var fittedBoundsSize: CGSize = .zero

    init(image: UIImage) {
        super.init(frame: .zero)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIgnoresInvertColors = true
        addSubview(imageView)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        bouncesZoom = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Re-fit only when the available size changes, never in the middle of a zoom.
        guard bounds.size != fittedBoundsSize, bounds.width > 0, bounds.height > 0 else { return }
        fittedBoundsSize = bounds.size
        zoomScale = 1
        let size = imageView.image?.size ?? CGSize(width: 1, height: 1)
        let ratio = size.height / max(size.width, 1)
        var width = bounds.width
        var height = width * ratio
        if height > bounds.height {
            height = bounds.height
            width = height / max(ratio, 0.0001)
        }
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        contentSize = imageView.frame.size
        centerHorizontally()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerHorizontally()
    }

    /// A page narrower than the view stays centred left-right; it stays at the top (Figma).
    private func centerHorizontally() {
        let horizontal = max(0, (bounds.width - imageView.frame.width) / 2)
        contentInset = UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal)
    }

    @objc private func doubleTapped(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
            return
        }
        let point = gesture.location(in: imageView)
        let scale: CGFloat = 2.5
        let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
        zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
    }
}
