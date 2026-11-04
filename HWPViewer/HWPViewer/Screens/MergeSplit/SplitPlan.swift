//
//  SplitPlan.swift
//  HWPViewer
//
//  What the user has set on the Split screen, independent of the UI: mode, custom ranges, picked
//  pages, pages-per-file. Pages are 1-based throughout (the engine's extract API is 1-based too).
//

import UIKit

struct SplitPlan {
    enum Mode: Int, CaseIterable {
        case ranges, pick, every
    }

    let pageCount: Int
    var mode: Mode = .ranges
    /// Custom parts (Page ranges mode), edited row by row; may be invalid while typing.
    var ranges: [ClosedRange<Int>]
    var picked: Set<Int> = []
    var onePerPage = false
    var pagesPerFile: Int

    init(pageCount: Int) {
        self.pageCount = max(pageCount, 1)
        let half = (self.pageCount + 1) / 2
        ranges = self.pageCount >= 2 ? [1...half, (half + 1)...self.pageCount] : [1...1]
        pagesPerFile = max(1, self.pageCount / 2)
    }

    /// Parts the split will write, in order (ranges / every modes).
    var parts: [ClosedRange<Int>] {
        switch mode {
        case .ranges:
            return ranges
        case .every:
            return stride(from: 1, through: pageCount, by: pagesPerFile).map { $0...min($0 + pagesPerFile - 1, pageCount) }
        case .pick:
            return onePerPage ? picked.sorted().map { $0...$0 } : []
        }
    }

    var isValid: Bool {
        switch mode {
        case .ranges: return !ranges.isEmpty && ranges.allSatisfy { $0.lowerBound >= 1 && $0.upperBound <= pageCount }
        case .every: return pagesPerFile >= 1
        case .pick: return !picked.isEmpty
        }
    }

    /// Number of files the action will create.
    var outputCount: Int {
        mode == .pick && !onePerPage ? (picked.isEmpty ? 0 : 1) : parts.count
    }

    var actionTitle: String {
        mode == .pick ? L10n.splitExtractAction(picked.count) : L10n.splitAction(outputCount)
    }

    /// Color band of `page` in ranges / every modes (first matching part wins), nil if in no part.
    func partColor(of page: Int) -> UIColor? {
        guard mode != .pick, let index = parts.firstIndex(where: { $0.contains(page) }) else { return nil }
        return Self.color(part: index)
    }

    static func color(part index: Int) -> UIColor {
        AppColors.splitParts[index % AppColors.splitParts.count]
    }
}
