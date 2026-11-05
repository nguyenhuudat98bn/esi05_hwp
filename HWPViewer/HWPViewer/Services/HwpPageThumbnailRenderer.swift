//
//  HwpPageThumbnailRenderer.swift
//  HWPViewer
//
//  Page thumbnails for the Split screen: one engine document per file, pages rendered to PDF by the
//  engine (`renderPDF(page:)`) and rasterised with PDFKit. All engine calls go through one serial
//  queue (a document handle must not be used from two threads at once); images are cached.
//

import UIKit
import PDFKit
import HwpEditorKit

/// `@unchecked Sendable`: the engine document is only touched on `queue`; NSCache is thread-safe.
final class HwpPageThumbnailRenderer: @unchecked Sendable {
    private let url: URL
    private let queue = DispatchQueue(label: "hwp.thumbnails", qos: .userInitiated)
    private let cache = NSCache<NSNumber, UIImage>()
    private var document: RhwpDocument?

    init(url: URL) {
        self.url = url
        cache.countLimit = 120
    }

    /// Opens the document (call after `HwpEngine.prepare()`); returns its page count.
    func open() async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                do {
                    let document = try RhwpDocument(contentsOf: url)
                    self.document = document
                    continuation.resume(returning: document.pageCount)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Thumbnail of 1-based `page`, `width` points wide at `scale`; nil when rendering fails or the
    /// calling task was cancelled before its turn on the queue (the cell scrolled away).
    func thumbnail(page: Int, width: CGFloat, scale: CGFloat) async -> UIImage? {
        let key = NSNumber(value: page)
        if let cached = cache.object(forKey: key) { return cached }
        let request = ThumbnailRequest()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                queue.async { [self] in
                    // Rendered meanwhile by an earlier request for the same page.
                    if let cached = cache.object(forKey: key) { return continuation.resume(returning: cached) }
                    guard !request.isCancelled, let document,
                          let data = try? document.renderPDF(page: page - 1),
                          let pdfPage = PDFDocument(data: data)?.page(at: 0) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let bounds = pdfPage.bounds(for: .mediaBox)
                    let height = width * bounds.height / max(bounds.width, 1)
                    let image = pdfPage.thumbnail(of: CGSize(width: width * scale, height: height * scale), for: .mediaBox)
                    cache.setObject(image, forKey: key)
                    continuation.resume(returning: image)
                }
            }
        } onCancel: {
            request.cancel()
        }
    }
}

/// Cancellation flag shared between the caller's task and the render queue.
private final class ThumbnailRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }
}
