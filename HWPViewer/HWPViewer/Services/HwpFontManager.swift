//
//  HwpFontManager.swift
//  HWPViewer
//
//  Downloads + caches the Noto KR fonts the HWP engine needs (not bundled to keep the IPA small).
//  Files come as `.otf.xz`, decompressed with LZMA and verified with SHA-256. Ported from NI03.
//

import Foundation
import CryptoKit
import HwpEditorKit

enum HwpFontError: LocalizedError {
    case network
    case corrupted

    var errorDescription: String? {
        switch self {
        case .network: return L10n.popupOfflineMessage
        case .corrupted: return L10n.popupErrorTitle
        }
    }
}

@MainActor
final class HwpFontManager {
    static let shared = HwpFontManager()

    private struct RemoteFont: Sendable {
        let fileName: String
        let sha256: String
    }

    private let fonts: [RemoteFont] = [
        .init(fileName: "NotoSansKR-Regular.otf",
              sha256: "69975a0ac8472717870aefeab0a4d52739308d90856b9955313b2ad5e0148d68"),
        .init(fileName: "NotoSerifKR-Regular.otf",
              sha256: "5ea012e15cb7eacc1f680aee1703f3b164791b1443ea3e52b65080cca5d179cf"),
    ]

    static let defaultBaseURL = "https://raw.githubusercontent.com/nguyenhuudat98bn/NotoSFont/main/fonts"

    private var baseURL: String {
        if let remote = AppRemoteConfigs.current.hwpFontsBaseUrl, !remote.isEmpty {
            return remote
        }
        return Self.defaultBaseURL
    }

    let fontsDirectory: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HwpFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var verifiedThisLaunch = false
    private var inflight: Task<Void, Error>?

    /// Quick check for UI (existence only; checksum verified in `ensureFonts`).
    var isReady: Bool {
        if verifiedThisLaunch { return true }
        return fonts.allSatisfy {
            FileManager.default.fileExists(atPath: fontsDirectory.appendingPathComponent($0.fileName).path)
        }
    }

    /// Home calls this so the download happens before the user opens a file.
    func prefetchIfNeeded() {
        guard !verifiedThisLaunch, inflight == nil else { return }
        Task { try? await ensureFonts() }
    }

    /// Returns immediately when every font is present with the right checksum; downloads what is missing.
    func ensureFonts() async throws {
        if verifiedThisLaunch { return }
        if let inflight {
            try await inflight.value
            return
        }
        let fonts = self.fonts
        let dir = fontsDirectory
        let base = baseURL
        let task = Task.detached(priority: .userInitiated) {
            for font in fonts {
                let dest = dir.appendingPathComponent(font.fileName)
                if let data = try? Data(contentsOf: dest), Self.sha256Hex(data) == font.sha256 {
                    continue
                }
                guard let url = URL(string: "\(base)/\(font.fileName).xz") else { throw HwpFontError.network }
                let (xzData, response) = try await URLSession.shared.data(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw HwpFontError.network }
                let data = try (xzData as NSData).decompressed(using: .lzma) as Data
                guard Self.sha256Hex(data) == font.sha256 else { throw HwpFontError.corrupted }
                try data.write(to: dest, options: .atomic)
            }
        }
        inflight = task
        defer { inflight = nil }
        do {
            try await task.value
        } catch let error as HwpFontError {
            throw error
        } catch {
            throw HwpFontError.network
        }
        verifiedThisLaunch = true
        HwpEngineBootstrap.fontsDirectoryOverride = fontsDirectory
    }

    private nonisolated static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
