//
//  OcrFlow.swift
//  HWPViewer
//
//  Entry of "OCR to HWP" (Figma section "OCR", 6988:130354): camera permission, then the scanner.
//  The scanner always opens — Photos needs no camera permission. Without camera access the
//  "Allow Camera Access" popup (7011:116498) comes up over it, and again on the shutter.
//  No camera at all (simulator) → the scanner opens with the shutter off; Photos works there.
//

import UIKit
import AVFoundation

enum OcrFlow {
    static func start(from presenter: UIViewController) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // Denied right here: the user just said no, no popup on top of that; the shutter explains.
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async { openScanner(from: presenter, explainCameraAccess: false) }
            }
        case .denied, .restricted:
            openScanner(from: presenter, explainCameraAccess: AVCaptureDeviceAvailability.hasCamera)
        case .authorized:
            openScanner(from: presenter, explainCameraAccess: false)
        @unknown default:
            openScanner(from: presenter, explainCameraAccess: false)
        }
    }

    private static func openScanner(from presenter: UIViewController, explainCameraAccess: Bool) {
        let scanner = OcrCameraViewController()
        scanner.explainsCameraAccessOnAppear = explainCameraAccess
        presenter.navigationController?.pushViewController(scanner, animated: true)
    }
}
