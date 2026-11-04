//
//  OcrFlow.swift
//  HWPViewer
//
//  Entry of "OCR to HWP" (Figma section "OCR", 6988:130354): camera permission, then the scanner.
//  Denied / restricted → "Allow Camera Access" popup over the current screen (7011:116498).
//  No camera at all (simulator) → the scanner still opens; Photos works there.
//

import UIKit
import AVFoundation

enum OcrFlow {
    static func start(from presenter: UIViewController) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            openScanner(from: presenter)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted || !AVCaptureDeviceAvailability.hasCamera {
                        openScanner(from: presenter)
                    } else {
                        presenter.present(CameraPermissionPopupViewController(), animated: true)
                    }
                }
            }
        case .denied, .restricted:
            if AVCaptureDeviceAvailability.hasCamera {
                presenter.present(CameraPermissionPopupViewController(), animated: true)
            } else {
                openScanner(from: presenter)
            }
        @unknown default:
            openScanner(from: presenter)
        }
    }

    private static func openScanner(from presenter: UIViewController) {
        presenter.navigationController?.pushViewController(OcrCameraViewController(), animated: true)
    }
}
