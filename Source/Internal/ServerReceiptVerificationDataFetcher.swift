import Foundation

internal final class ServerReceiptVerificationResponseDataFetcher {
    public typealias Completion = (Result<Data, Error>) -> Void
    
    var onCompletion: Completion?
    
    fileprivate let session = URLSession(configuration: .default)
    
    let verificationData: Data
    let environment: StoreEnvironment
    let sharedSecret: String?
    
    internal init(verificationData: Data, environment: StoreEnvironment, sharedSecret: String?) {
        self.verificationData = verificationData
        self.environment = environment
        self.sharedSecret = sharedSecret
    }
    
    public func start() {
        self.sendServerRequest(for: self.environment)
    }
    
    internal enum StoreEnvironment {
        case sandbox
        case production
    }
}

extension ServerReceiptVerificationResponseDataFetcher {
    private func complete(with result: Result<Data, Error>) {
        self.onCompletion?(result)
    }
    
    private func urlForVerification(in environment: StoreEnvironment) -> URL {
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
                "receipt-data": self.verificationData.base64EncodedString(),
                "password": self.sharedSecret ?? ""
            ]
            
            let requestData = try! JSONSerialization.data(withJSONObject: requestDictionary, options: [])
            
            var request = URLRequest(url: self.urlForVerification(in: environment))
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
        if let error = error {
            self.complete(with: .failure(error))
        } else {
            self.complete(with: .success(data!))
        }
    }
}
