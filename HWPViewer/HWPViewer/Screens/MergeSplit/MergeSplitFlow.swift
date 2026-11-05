//
//  MergeSplitFlow.swift
//  HWPViewer
//
//  Entry points of the two Tools flows (Figma "Merge HWP" 6978:109459, "Split HWP" 6978:110902):
//  - Merge: Select Files (multi) → Merge Files (order / remove / add) → name → loading → done.
//  - Split: Select a file → Selected (n) pages → name → loading → done.
//

import UIKit

enum MergeSplitFlow {
    static func startMerge(on navigationController: UINavigationController) {
        let picker = HwpFilePickerViewController(mode: .multiple(minimum: 2))
        picker.onPicked = { [weak navigationController] files in
            navigationController?.pushViewController(MergeFilesViewController(files: files), animated: true)
        }
        navigationController.pushViewController(picker, animated: true)
    }

    static func startSplit(on navigationController: UINavigationController) {
        let picker = HwpFilePickerViewController(mode: .single)
        picker.onPicked = { [weak navigationController] files in
            guard let file = files.first else { return }
            navigationController?.pushViewController(SplitPagesViewController(item: file), animated: true)
        }
        navigationController.pushViewController(picker, animated: true)
    }
}
