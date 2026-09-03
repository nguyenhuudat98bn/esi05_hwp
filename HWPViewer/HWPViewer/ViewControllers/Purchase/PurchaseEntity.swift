//
//  PurchaseEntity.swift
//  HWPViewer
//
//  Created by Eragon on 25/8/25.
//

import SPNComponent
import Foundation

struct Product {
    let id: String
    let title: String
    let name: String
    let description: String
    let price: String
    let pricePerWeek: String
    let freeDayTrial: String
    let isBestValue: Bool
}

enum ProductItem: String, CaseIterable {
    case week
    case year
    
    init(rawValue: String) {
        switch rawValue {
        case "com.spn.scanxpro.weekly":
            self = .week
        case "com.spn.scanxpro.yearly":
            self = .year
        default:
            self = .week
        }
    }
    
    var identifier: String {
        switch self {
        case .week:
            return "com.spn.scanxpro.weekly"
        case .year:
            return "com.spn.scanxpro.yearly"
        }
    }
    
    var title: String {
        switch self {
        case .week:
            return L10n.purchase1Week
        case .year:
            return L10n.purchase1Year
        }
    }
    
    var name: String {
        switch self {
        case .week:
            return L10n.purchaseWeekly
        case .year:
            return L10n.purchaseYearly
        }
    }
    
    var isBestValue: Bool {
        switch self {
        case .week:
            return false
        case .year:
            return true
        }
    }
}
