//
//  OcrCameraSession.swift
//  HWPViewer
//
//  Back camera for the OCR scanner: preview layer, live page detection (Vision rectangles on video
//  frames, ~6 per second) reported as a quad in preview-layer coordinates, and still capture.
//  No camera (simulator) → `isAvailable == false`, the screen keeps working with Photos only.
//

import AVFoundation
import UIKit
import Vision

/// `@unchecked Sendable`: session state is touched on `queue`, UI callbacks hop to the main thread.
final class OcrCameraSession: NSObject, @unchecked Sendable {
    let previewLayer = AVCaptureVideoPreviewLayer()
    /// Detected page corners in preview-layer coordinates (TL, TR, BR, BL), nil when none. Main thread.
    var onPageQuad: (([CGPoint]?) -> Void)?
    private(set) var isAvailable = false

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "ocr.camera.session")
    private let detectionQueue = DispatchQueue(label: "ocr.camera.detect", qos: .userInitiated)
    private var lastDetection = Date.distantPast
    private var captureContinuation: CheckedContinuation<UIImage, Error>?

    override init() {
        super.init()
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }

    /// Configures and starts the session (call once permission is granted).
    func start() {
        queue.async { [self] in
            if !isAvailable { configure() }
            guard isAvailable, !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stop() {
        queue.async { [self] in if session.isRunning { session.stopRunning() } }
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard session.canAddInput(input), session.canAddOutput(photoOutput), session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: detectionQueue)
        session.addOutput(videoOutput)
        session.commitConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
            try? device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            device.unlockForConfiguration()
        }
        isAvailable = true
    }

    /// Takes a photo (upright `UIImage` with its EXIF orientation).
    func capture() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                guard isAvailable else {
                    continuation.resume(throwing: OcrError.unreadableImage)
                    return
                }
                captureContinuation = continuation
                photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        }
    }
}

extension OcrCameraSession: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let continuation = captureContinuation
        captureContinuation = nil
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            continuation?.resume(returning: image)
        } else {
            continuation?.resume(throwing: error ?? OcrError.unreadableImage)
        }
    }
}

extension OcrCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard Date().timeIntervalSince(lastDetection) > 0.16, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastDetection = Date()
        let request = DocumentRectangleDetector.makeRequest()
        // Detect in sensor (buffer) space: Vision's bottom-left normalised points flip into capture-device points.
        try? VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:]).perform([request])
        let quad = request.results?.first
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let quad else { onPageQuad?(nil); return }
            let corners = [quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft].map {
                self.previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: $0.x, y: 1 - $0.y))
            }
            onPageQuad?(corners)
        }
    }
}
