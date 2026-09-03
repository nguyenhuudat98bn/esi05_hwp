//
//  ReceiptValidator.swift
//  
//
//  Created by datnh on 01/4/25.
//

import SPNComponent
import Foundation
import UIKit

enum ReceiptValidationResult {
    case active
    case expired
    case isSandbox
    case validationFailure
    case invalidate
}

class ReceiptValidator {
    
    typealias ValidateReceiptCallback = (ReceiptValidationResult) -> Void
    
    private let receiptURL = Bundle.main.appStoreReceiptURL
    
    func validateReceipt(isSwitchEvr: Bool = false ,completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let verifyReceiptDomain = isSwitchEvr ? "https://sandbox.itunes.apple.com/verifyReceipt" : "https://buy.itunes.apple.com/verifyReceipt"
        guard let receiptURL = receiptURL,
              let verifyReceiptDomainURL = URL(string: verifyReceiptDomain),
                FileManager.default.fileExists(atPath: receiptURL.path) else {
            completion(.failure(NSError(domain: "ReceiptValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Receipt not found"])))
            return
        }
        
        do {
            let receiptData = try Data(contentsOf: receiptURL)
            let receiptString = receiptData.base64EncodedString(options: [])
            
            // Create the request payload
            let requestPayload: [String: Any] = ["receipt-data": receiptString,
                                                 "password": ""]
            let requestData = try JSONSerialization.data(withJSONObject: requestPayload, options: [])
            
            // Create the request
            var request = URLRequest(url: verifyReceiptDomainURL)
            request.httpMethod = "POST"
            request.httpBody = requestData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Perform the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                logger("=======> \(data) response\(response)error\(error) ")
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "ReceiptValidator", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                if let dataString = String(data: data, encoding: .utf8) {
                    logger("Raw JSON Data: \(dataString)")
                }
                
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    completion(.success(jsonResponse ?? [:]))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func checkSubscriptionStatus(receipt: [String: Any]) -> Bool {
        guard let receiptInfo = receipt["latest_receipt_info"] as? [[String: Any]] else {
            logger("No subscription info found in the receipt")
            return false
        }
        
        var isSubscriptionActive = false
        
        for purchase in receiptInfo {
            if let productID = purchase["product_id"] as? String,
               let expiresDateMs = purchase["expires_date_ms"] as? String {
                
                let expiresDate = Date(timeIntervalSince1970: TimeInterval(expiresDateMs)! / 1000)
                
                logger("Product ID: \(productID)")
                logger("Expiration Date: \(expiresDate)")
                
                // Compare the expiration date to the current date
                if expiresDate > Date() {
                    isSubscriptionActive = true
                    ApplicationSession.shared.subscriptionPackage = productID
                    break // Exit the loop early if a valid subscription is found
                }
            }
        }
        
        return isSubscriptionActive
    }
        
    func handleReceiptValidation(response: [String: Any], isSwitchEvr: Bool = false, completion: (ValidateReceiptCallback)) {
        guard let status = response["status"] as? Int else {
            completion(.invalidate)
            logger("Invalid receipt validation response")
            return
        }
        
        if status == 0 {
            logger("Receipt is valid")
            if checkSubscriptionStatus(receipt: response) {
                logger("Subscription is active")
                // Grant access to subscription content
                completion(.active)
            } else {
                completion(.expired)
                logger("Subscription is inactive or expired")
                // Handle expired or inactive subscription
            }
        } else if status == 21007 {
            if isSwitchEvr {
                completion(.isSandbox)
                logger("Receipt is from the sandbox environment; validate against the sandbox server")
            } else {
                logger("Receipt is from the sandbox environment; validate against the sandbox server retry")
                StoreKitManager.shared.validateReceipt(isSwitchEvr: true)
            }
            // Retry validation against the sandbox URL
        } else {
            completion(.validationFailure)
            logger("Receipt validation failed with status: \(status)")
            // Handle receipt validation failure
        }
    }
}
