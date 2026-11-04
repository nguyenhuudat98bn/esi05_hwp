//
//  ToolKind.swift
//  HWPViewer
//
//  The Tools entries (Figma G1 + Merge / Split HWP POC) and the Select File family each one needs.
//

import UIKit

enum ToolKind: CaseIterable {
    case editHwp, pdfToHwp, docToHwp, print, mergeHwp, splitHwp, ocr

    var title: String {
        switch self {
        case .editHwp: return L10n.homeCardEditHwp
        case .pdfToHwp: return L10n.homeCardPdfToHwp
        case .docToHwp: return L10n.homeCardDocToHwp
        case .print: return L10n.homeCardPrint
        case .mergeHwp: return L10n.toolsMergeHwp
        case .splitHwp: return L10n.toolsSplitHwp
        case .ocr: return L10n.toolsOcr
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
        case .ocr: return L10n.toolsOcrSubtitle
        }
    }

    /// Full-card artwork (gradient + illustration baked in, 156×88 @2x/@3x). `nil` → gradient + rotated `art`.
    var cardBackground: UIImage? {
        switch self {
        case .editHwp: return Asset.Assets.App.imgCardEditHwpBg.image
        case .pdfToHwp: return Asset.Assets.App.imgCardPdfToHwpBg.image
        case .docToHwp: return Asset.Assets.App.imgCardDocToHwpBg.image
        case .print: return Asset.Assets.App.imgCardPrintBg.image
        case .mergeHwp: return Asset.Assets.App.imgCardMergeBg.image
        case .splitHwp: return Asset.Assets.App.imgCardSplitBg.image
        // Figma 7011:115391: gradient + Rect Light + scanner glyph, composed into one image.
        case .ocr: return Asset.Assets.App.imgCardOcrBg.image
        }
    }

    var art: UIImage? {
        switch self {
        case .editHwp: return Asset.Assets.App.icCardEditHwpVector.image
        case .pdfToHwp: return Asset.Assets.App.icCardPdfReader.image
        case .docToHwp: return Asset.Assets.App.icCardWordDoc.image
        case .print: return Asset.Assets.App.icCardPrint.image
        // Art baked into the card background (img_card_merge_bg / _split_bg / _ocr_bg).
        case .mergeHwp, .splitHwp, .ocr: return nil
        }
    }

    var artRotation: CGFloat {
        switch self {
        case .editHwp: return -17.7
        case .pdfToHwp: return 0
        case .docToHwp: return -17.4
        case .print: return -13.5
        case .mergeHwp, .splitHwp, .ocr: return -12
        }
    }

    var artSize: CGFloat {
        switch self {
        case .editHwp: return 52
        case .pdfToHwp: return 51
        case .docToHwp: return 62
        case .print: return 80
        case .mergeHwp, .splitHwp, .ocr: return 50
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
        case .ocr: return AppColors.pillOcr
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
        case .ocr: return AppColors.gradientOcr
        }
    }

    /// Which files the Select File screen lists.
    var family: FileFamily {
        switch self {
        case .editHwp, .print, .mergeHwp, .splitHwp, .ocr: return .hwp
        case .pdfToHwp: return .pdf
        case .docToHwp: return .doc
        }
    }

    var isConvert: Bool { self == .pdfToHwp || self == .docToHwp }
}
