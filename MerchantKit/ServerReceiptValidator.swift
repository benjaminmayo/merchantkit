import Foundation

public final class ServerReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let receiptData: Data
    
    public var onCompletion: Completion?
    
    fileprivate let session = URLSession(configuration: .default)
    fileprivate let sharedSecret: String
    
    public init(receiptData: Data, sharedSecret: String) {
        self.receiptData = receiptData
        self.sharedSecret = sharedSecret
    }
    
    public func start() {
        self.sendServerRequest(for: .production)
    }
}

extension ServerReceiptValidator {
    private func complete(with result: Result<Receipt>) {
        self.onCompletion?(result)
    }
    
    fileprivate enum StoreEnvironment {
        case sandbox
        case production
    }
    
    private func urlForValidation(in environment: StoreEnvironment) -> URL {
        switch environment {
            case .sandbox:
                return URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
            case .production:
                return URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        }
    }

    fileprivate func sendServerRequest(for environment: StoreEnvironment) {
        let urlRequest: URLRequest = {
            let requestDictionary: [String : Any] = [
                "receipt-data": self.receiptData.base64EncodedString(),
                "password": self.sharedSecret
            ]
            
            let requestData = try! JSONSerialization.data(withJSONObject: requestDictionary, options: [])
            
            var request = URLRequest(url: self.urlForValidation(in: environment))
            request.httpMethod = "POST"
            request.httpBody = requestData
            
            return request
        }()
        
        let task = self.session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            self.didReceiveServerResponse(data: data, error: error)
        })
        
        task.resume()
    }
    
    private func didReceiveServerResponse(data: Data?, error: Error?) {
        do {
            if let error = error {
                throw error
            } else if let data = data {
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let object = json as? [String : Any] else { throw ResponseError.noData }
                                
                guard let status = object["status"] as? Int else { throw ResponseError.malformed }
                
                if status != 0 {
                    throw ReceiptServerError(rawValue: status)!
                }
                
                guard let receiptObject = object["receipt"] as? [String : Any] else { throw ResponseError.malformed }
                
                let validated = try self.validatedReceipt(from: receiptObject)
                
                self.complete(with: .succeeded(validated))
            }
        } catch ReceiptServerError.receiptIncompatibleWithProductionEnvironment {
            self.sendServerRequest(for: .sandbox)
        } catch let error {
            print(error)
            
            self.complete(with: .failed(error))
        }
    }
    
    private func validatedReceipt(from object: [String : Any]) throws -> Receipt {
        guard let inAppPurchaseInfos = object["in_app"] as? [[String : Any]] else { throw ReceiptParseError.malformed }
        
        var allInfos = inAppPurchaseInfos
        
        if let latestPurchaseInfos = object["latest_receipt_info"] as? [[String : Any]] {
            allInfos.append(contentsOf: latestPurchaseInfos)
        }
    
        let entries = try allInfos.map { info in
            try self.receiptEntry(fromJSONObject: info)
        }
        
        let receipt = ConstructedReceipt(from: entries)
        
        return receipt
    }
        
    private enum ResponseError : Swift.Error {
        case noData
        case malformed
    }
    
    private enum ReceiptServerError : Int, Swift.Error {
        case generic = 21000
        case malformedRequest = 21002
        case authenticationFailed = 21003
        case sharedSecretNotMatch = 21004
        case receiptServerUnavailable = 21005
        case receiptIncompatibleWithProductionEnvironment = 21007
        case receiptIncompatibleWithSandboxEnvironment = 21008
    }
    
    private enum ReceiptParseError : Swift.Error {
        case malformed
    }
    
    private func receiptEntry(fromJSONObject object: [String : Any]) throws -> ReceiptEntry {
        guard let productIdentifier = object["product_id"] as? String else { throw ReceiptParseError.malformed }
        
        let expiryDate: Date?
        if let formattedExpiry = object["expires_date_ms"] as? String, let milliseconds = Int(formattedExpiry) {
            expiryDate = Date(millisecondsSince1970: milliseconds)
        } else {
            expiryDate = nil
        }
        
        return ReceiptEntry(productIdentifier: productIdentifier, expiryDate: expiryDate)
    }
}
