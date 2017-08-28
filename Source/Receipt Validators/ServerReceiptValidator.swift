/// Sends a validation request to the iTunes server. 
/// Attempts to make a validated receipt from the response and calls `onCompletion` when finished.
public final class ServerReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let request: ReceiptValidationRequest
    
    public var onCompletion: Completion?
    
    fileprivate let session = URLSession(configuration: .default)
    fileprivate let sharedSecret: String
    
    public init(request: ReceiptValidationRequest, sharedSecret: String) {
        self.request = request
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
                "receipt-data": self.request.data.base64EncodedString(),
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
                let parser = ServerReceiptResponseParser() // this object handles the actual parsing of the data
                let validatedReceipt = try parser.receipt(from: data)
                
                self.complete(with: .succeeded(validatedReceipt))
            }
        } catch ServerReceiptResponseParser.ReceiptStatusError.receiptIncompatibleWithProductionEnvironment {
            self.sendServerRequest(for: .sandbox)
        } catch let error {            
            self.complete(with: .failed(error))
        }
    }
}
