//
//  LoadingOverlayViewController.swift
//  HWPViewer
//
//  "Loading" state of Merge / Split (Figma 6978:109119 / 6978:110688): the screen dimmed with the
//  app overlay colour and a 160pt spinner in the middle — no card, no text, not cancellable.
//  The spinner is the design's own animation ("loading (4) 1", a 60-frame / 2 s GIF of a growing
//  blue arc), kept as the data asset `anim_loading_arc`.
//

import UIKit
import SnapKit
import ImageIO

final class LoadingOverlayViewController: UIViewController {
    private let work: () async throws -> [DocumentOutput]
    private let onFinished: (Result<[DocumentOutput], Error>) -> Void

    init(work: @escaping () async throws -> [DocumentOutput],
         onFinished: @escaping (Result<[DocumentOutput], Error>) -> Void) {
        self.work = work
        self.onFinished = onFinished
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.dim
        let spinner: UIView
        if let animation = Self.loadingAnimation() {
            let imageView = UIImageView(image: animation)
            imageView.contentMode = .scaleAspectFit
            spinner = imageView
        } else {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .white
            indicator.startAnimating()
            spinner = indicator
        }
        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(160)
        }
        view.accessibilityViewIsModal = true
        spinner.isAccessibilityElement = true
        spinner.accessibilityLabel = L10n.mergeSplitLoading
    }

    /// Frames + total duration of the design GIF.
    private static func loadingAnimation() -> UIImage? {
        guard let data = NSDataAsset(name: Asset.Assets.App.animLoadingArc.name)?.data,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        var frames: [UIImage] = []
        var duration: Double = 0
        for index in 0..<CGImageSourceGetCount(source) {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: frame))
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double) ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0
            duration += delay > 0.01 ? delay : 0.033
        }
        return frames.isEmpty ? nil : UIImage.animatedImage(with: frames, duration: duration)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: view.subviews.first)
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result: Result<[DocumentOutput], Error>
            do {
                result = .success(try await work())
            } catch {
                result = .failure(error)
            }
            dismiss(animated: true) { [onFinished] in onFinished(result) }
        }
    }
}
