import Foundation
import Security

public final class ServerReceiptValidator {
    public let receipt: Receipt
    fileprivate let session = URLSession(configuration: .default)
    fileprivate let sharedSecret: String
    
    public init(receipt: Receipt, sharedSecret: String) {
        self.receipt = receipt
        self.sharedSecret = sharedSecret
    }
    
    func validate() {
        
    }
}

extension ServerReceiptValidator {
    private enum StoreEnvironment {
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

    private func sendServerRequest(for environment: StoreEnvironment) {
        let urlRequest: URLRequest = {
            let requestDictionary: [String : Any] = [
                "receipt-data": self.receipt.data.base64EncodedString(),
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
            }
        } catch ReceiptServerError.receiptIncompatibleWithProductionEnvironment {
            self.sendServerRequest(for: .sandbox)
        } catch let error {
            print(error)
        }
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
        case recenitIncompatibleWithSandboxEnvironment = 21008
    }
}
