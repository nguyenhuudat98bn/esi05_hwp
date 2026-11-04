//
//  ToolKind.swift
//  HWPViewer
//
//  The Tools entries (Figma G1 + Merge / Split HWP POC) and the Select File family each one needs.
//

import UIKit

enum ToolKind: CaseIterable {
    case editHwp, pdfToHwp, docToHwp, print, mergeHwp, splitHwp

    var title: String {
        switch self {
        case .editHwp: return L10n.homeCardEditHwp
        case .pdfToHwp: return L10n.homeCardPdfToHwp
        case .docToHwp: return L10n.homeCardDocToHwp
        case .print: return L10n.homeCardPrint
        case .mergeHwp: return L10n.toolsMergeHwp
        case .splitHwp: return L10n.toolsSplitHwp
        }
    }

    var subtitle: String {
        switch self {
        case .editHwp: return L10n.homeCardEditHwpSubtitle
        case .pdfToHwp: return L10n.homeCardPdfToHwpSubtitle
        case .docToHwp: return L10n.homeCardDocToHwpSubtitle
        case .print: return L10n.homeCardPrintSubtitle
        case .mergeHwp: return L10n.toolsMergeHwpSubtitle
        case .splitHwp: return L10n.toolsSplitHwpSubtitle
        }
    }

    /// Full-card artwork (gradient + illustration baked in, 156×88 @2x/@3x). `nil` → gradient + rotated `art`.
    var cardBackground: UIImage? {
        switch self {
        case .editHwp: return Asset.Assets.App.imgCardEditHwpBg.image
        case .pdfToHwp: return Asset.Assets.App.imgCardPdfToHwpBg.image
        case .docToHwp: return Asset.Assets.App.imgCardDocToHwpBg.image
        case .print: return Asset.Assets.App.imgCardPrintBg.image
        case .mergeHwp, .splitHwp: return nil
        }
    }

    var art: UIImage? {
        switch self {
        case .editHwp: return Asset.Assets.App.icCardEditHwpVector.image
        case .pdfToHwp: return Asset.Assets.App.icCardPdfReader.image
        case .docToHwp: return Asset.Assets.App.icCardWordDoc.image
        case .print: return Asset.Assets.App.icCardPrint.image
        // POC placeholders until the card artwork is exported from the design.
        case .mergeHwp: return UIImage(systemName: "doc.on.doc.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        case .splitHwp: return UIImage(systemName: "scissors")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        }
    }

    var artRotation: CGFloat {
        switch self {
        case .editHwp: return -17.7
        case .pdfToHwp: return 0
        case .docToHwp: return -17.4
        case .print: return -13.5
        case .mergeHwp, .splitHwp: return -12
        }
    }

    var artSize: CGFloat {
        switch self {
        case .editHwp: return 52
        case .pdfToHwp: return 51
        case .docToHwp: return 62
        case .print: return 80
        case .mergeHwp, .splitHwp: return 50
        }
    }

    var pillColor: UIColor {
        switch self {
        case .editHwp: return AppColors.pillEdit
        case .pdfToHwp: return AppColors.pillPdf
        case .docToHwp: return AppColors.pillDoc
        case .print: return AppColors.pillPrint
        case .mergeHwp: return AppColors.pillMerge
        case .splitHwp: return AppColors.pillSplit
        }
    }

    var gradient: [UIColor] {
        switch self {
        case .editHwp: return AppColors.gradientEdit
        case .pdfToHwp: return AppColors.gradientPdf
        case .docToHwp: return AppColors.gradientDoc
        case .print: return AppColors.gradientPrint
        case .mergeHwp: return AppColors.gradientMerge
        case .splitHwp: return AppColors.gradientSplit
        }
    }

    /// Which files the Select File screen lists.
    var family: FileFamily {
        switch self {
        case .editHwp, .print, .mergeHwp, .splitHwp: return .hwp
        case .pdfToHwp: return .pdf
        case .docToHwp: return .doc
        }
    }

    var isConvert: Bool { self == .pdfToHwp || self == .docToHwp }
}
