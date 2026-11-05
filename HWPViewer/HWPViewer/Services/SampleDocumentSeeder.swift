//
//  SampleDocumentSeeder.swift
//  HWPViewer
//
//  First launch only (as np12 Android's seedSampleDocumentIfNeeded): copies the bundled sample
//  documents (Resources/SampleDocuments — own content, built by scripts/sample-documents) into
//  Documents and marks them opened + bookmarked, so All files, Recent and Bookmark are not empty
//  on a fresh install. Runs once per install and never again — a user who deletes or renames the
//  samples does not get them back. Users updating from an older build (onboarding already done)
//  are skipped: the samples would land in a list they have filled themselves.
//

import Foundation
import SPNComponent

enum SampleDocumentSeeder {
    /// Same names as the intro art (Figma): newest "opened" first in Recent.
    private static let names = ["BusinessReport", "ProjectProposal", "WorkManual"]
    private static let seededKey = "SAMPLE_DOCUMENTS_SEEDED_V1"

    static func seedIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }
        defaults.set(true, forKey: seededKey)
        guard SPNSession.shared.isFirstTimeOnboard else { return }

        let store = FileStore.shared
        let now = Date()
        for (offset, name) in names.enumerated() {
            guard let source = Bundle.main.url(forResource: name, withExtension: "hwp") else {
                logger("[Samples] \(name).hwp missing from the bundle")
                continue
            }
            let destination = store.documentsURL.appendingPathComponent(source.lastPathComponent)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            do {
                try FileManager.default.copyItem(at: source, to: destination)
                // One second apart so Recent keeps this order.
                store.markSample(destination, openedAt: now.addingTimeInterval(-Double(offset)))
            } catch {
                logger("[Samples] copy \(name) failed: \(error)")
            }
        }
        store.notifyChanged()
    }
}
