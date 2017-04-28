/// Parse the server response from an iTunes Store network request.
internal struct ServerReceiptResponseParser {
    init() {
        
    }
    
    func receipt(from data: Data) throws -> Receipt {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let object = json as? [String : Any] else { throw ResponseDataError.malformed }
        
        guard let status = object["status"] as? Int else { throw ResponseDataError.missingOrInvalidKey("Status") }
        
        if status != 0 {
            throw ReceiptStatusError(rawValue: status) ?? .other
        }
        
        guard let receiptObject = object["receipt"] as? [String : Any] else { throw ResponseDataError.missingOrInvalidKey("receipt") }
        
        guard let inAppPurchaseInfos = receiptObject["in_app"] as? [[String : Any]] else { throw ResponseDataError.missingOrInvalidKey("in_app") }
        
        let allInfos: [[String : Any]]
        
        if let latestPurchaseInfos = receiptObject["latest_receipt_info"] as? [[String : Any]] {
            allInfos = inAppPurchaseInfos + latestPurchaseInfos
        } else {
            allInfos = inAppPurchaseInfos
        }
            
        let entries = try allInfos.map(self.receiptEntry(fromJSONObject:))
            
        let receipt = ConstructedReceipt(from: entries)
            
        return receipt
    }
    
    private func receiptEntry(fromJSONObject object: [String : Any]) throws -> ReceiptEntry {
        guard let productIdentifier = object["product_id"] as? String else { throw ResponseDataError.missingOrInvalidKey("product_id") }
        
        let expiryDate: Date?
        if let formattedExpiry = object["expires_date_ms"] as? String, let milliseconds = Int(formattedExpiry) {
            expiryDate = Date(millisecondsSince1970: milliseconds)
        } else {
            expiryDate = nil
        }
        
        return ReceiptEntry(productIdentifier: productIdentifier, expiryDate: expiryDate)
    }
    
    enum ResponseDataError : Swift.Error {
        case malformed
        case missingOrInvalidKey(String)
    }
    
    enum ReceiptStatusError : Int, Swift.Error {
        case malformedRequest = 21000
        case malformedReceiptData = 21002
        case authenticationFailed = 21003
        case sharedSecretNotMatch = 21004
        case receiptServerUnavailable = 21005
        case receiptIncompatibleWithProductionEnvironment = 21007
        case receiptIncompatibleWithSandboxEnvironment = 21008
        case other = -1 // other receipt errors
    }
    
}
