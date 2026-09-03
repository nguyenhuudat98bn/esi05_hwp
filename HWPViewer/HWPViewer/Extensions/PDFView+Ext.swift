//
//  PDFView+Ext.swift
//  HWPViewer
//
//  Created by datnh on 01/4/25.
//

import Foundation
import PDFKit

extension PDFView {
    var scrollView: UIScrollView? {
        return (self.subviews.first(where: {$0 is UIScrollView}) as? UIScrollView)
    }
}
