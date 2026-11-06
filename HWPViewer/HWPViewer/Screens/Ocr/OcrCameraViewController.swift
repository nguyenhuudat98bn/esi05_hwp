//
//  OcrCameraViewController.swift
//  HWPViewer
//
//  "Select from camera" (Figma 7011:115439): live camera full screen, the detected page outlined in
//  #16B5FD (2.4pt), bottom panel #181A20 (178pt) with close · shutter · Photos, 100pt apart.
//  The capture is flattened to the page (perspective correction) and goes to the preview screen.
//

import UIKit
import SnapKit
import PhotosUI
import AVFoundation
import Combine
import CombineCocoa

final class OcrCameraViewController: UIViewController, ToolFlowScreen {
    private let camera = OcrCameraSession()
    private let pageOutline = CAShapeLayer()
    private let panel = UIView()
    private let closeButton = UIButton(type: .custom)
    private let shutterButton = UIButton(type: .custom)
    private let galleryButton = UIButton(type: .custom)
    private var cancellables = Set<AnyCancellable>()
    private var isCapturing = false
    /// Covers the dead preview while camera access is not granted (ESI05-73).
    private let permissionView = OcrCameraPermissionView()
    /// Camera access denied: show "Allow Camera Access" once the scanner is up (Photos still works).
    var explainsCameraAccessOnAppear = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(camera.previewLayer)
        pageOutline.strokeColor = UIColor(hex: "#16B5FD").cgColor
        pageOutline.fillColor = UIColor.clear.cgColor
        pageOutline.lineWidth = 2.4
        pageOutline.lineJoin = .round
        view.layer.addSublayer(pageOutline)
        camera.onPageQuad = { [weak self] corners in self?.showPage(corners) }

        permissionView.isHidden = true
        view.addSubview(permissionView)
        permissionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(178) // above the bottom panel
        }
        // Back from Settings with access granted (or revoked): refresh the preview area.
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self, view.window != nil else { return }
                updatePermissionState()
                camera.start()
            }
            .store(in: &cancellables)

        panel.backgroundColor = UIColor(hex: "#181A20")
        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(178)
        }
        closeButton.setImage(Asset.Assets.App.icCameraClose.image, for: .normal)
        closeButton.accessibilityLabel = L10n.ocrClose
        shutterButton.setImage(Asset.Assets.App.icCameraShutter.image, for: .normal)
        shutterButton.accessibilityLabel = L10n.ocrTakePhoto
        galleryButton.setImage(Asset.Assets.App.icCameraGallery.image, for: .normal)
        galleryButton.accessibilityLabel = L10n.ocrChoosePhoto
        let row = UIStackView(arrangedSubviews: [closeButton, shutterButton, galleryButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 100 - 14 // 30pt icons sit in 44pt touch targets
        panel.addSubview(row)
        row.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(37)
        }
        closeButton.snp.makeConstraints { $0.size.equalTo(44) }
        galleryButton.snp.makeConstraints { $0.size.equalTo(44) }
        shutterButton.snp.makeConstraints { $0.size.equalTo(64) }

        closeButton.tapPublisher.sink { [weak self] _ in self?.close() }.store(in: &cancellables)
        shutterButton.tapPublisher.sink { [weak self] _ in self?.capture() }.store(in: &cancellables)
        galleryButton.tapPublisher.sink { [weak self] _ in self?.pickPhoto() }.store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        updatePermissionState()
        camera.start()
    }

    /// No camera access on a device that has a camera → explanation + "Open Settings" instead of a
    /// black preview. (No camera at all — simulator — keeps the plain dark scanner: Photos only.)
    private func updatePermissionState() {
        let authorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        permissionView.isHidden = authorized || !AVCaptureDeviceAvailability.hasCamera
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shutterButton.isEnabled = AVCaptureDeviceAvailability.hasCamera
        if explainsCameraAccessOnAppear {
            explainsCameraAccessOnAppear = false
            present(CameraPermissionPopupViewController(), animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        camera.stop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        camera.previewLayer.frame = view.bounds
    }

    private func showPage(_ corners: [CGPoint]?) {
        guard let corners, corners.count == 4 else {
            pageOutline.path = nil
            return
        }
        let path = UIBezierPath()
        path.move(to: corners[0])
        corners.dropFirst().forEach { path.addLine(to: $0) }
        path.close()
        pageOutline.path = path.cgPath
    }

    private func close() {
        navigationController?.popViewController(animated: true)
    }

    private func capture() {
        guard !isCapturing else { return }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            present(CameraPermissionPopupViewController(), animated: true)
            return
        }
        isCapturing = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isCapturing = false }
            guard let photo = try? await camera.capture() else { return }
            showPreview(await Self.page(from: photo, minimumCoverage: 0.2))
        }
    }

    private func pickPhoto() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showPreview(_ page: UIImage) {
        navigationController?.pushViewController(OcrPreviewViewController(page: page), animated: true)
    }

    /// The photo flattened to the page found in it (when the page covers enough of the photo).
    private static func page(from photo: UIImage, minimumCoverage: CGFloat) async -> UIImage {
        await Task.detached(priority: .userInitiated) {
            guard let upright = photo.uprightCGImage() else { return photo }
            return UIImage(cgImage: DocumentRectangleDetector.flattenedPage(from: upright, minimumCoverage: minimumCoverage))
        }.value
    }
}

extension OcrCameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            Task { @MainActor [weak self] in
                // Photos may be screenshots / scans already: only cut when a page clearly fills the picture.
                let page = await Self.page(from: image, minimumCoverage: 0.5)
                self?.showPreview(page)
            }
        }
    }
}

enum AVCaptureDeviceAvailability {
    static var hasCamera: Bool { AVCaptureDevice.default(for: .video) != nil }
}
