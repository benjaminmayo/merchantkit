/// Sends a request to the iTunes server for validation.
/// Attempts to make a validated receipt from the response and calls `onCompletion` when finished.
public final class ServerReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let request: ReceiptValidationRequest
    
    public var onCompletion: Completion?
    
    fileprivate let sharedSecret: String?
    
    private var dataFetcher: ServerReceiptVerificationResponseDataFetcher!
    
    /// Create a new server-based validator for the `request`, with optional `sharedSecret`. This validator uses a network request to get a response from the iTunes receipt verification server.
    /// - Parameter request: The validation request vended by the `Merchant` in the `merchant(_:validate:completion:)` delegate callback.
    /// - Parameter sharedSecret: The shared secret is only used by the iTunes Store validation server for receipts that contain auto-renewable subscriptions. Therefore, this value is technically optional. However, attempts to validate receipts containing auto-renewing subscriptions will fail if this value is not provided.
    /// - Note: `sharedSecret` cannot be `nil` if the `Merchant` is managing auto-renewing subscription products.
    public init(request: ReceiptValidationRequest, sharedSecret: String?) {
        self.request = request
        self.sharedSecret = sharedSecret
    }
    
    public func start() {
        self.dataFetcher = self.makeFetcher(for: .production)
        self.dataFetcher.start()
    }
}

extension ServerReceiptValidator {
    private func complete(with result: Result<Receipt>) {
        self.onCompletion?(result)
    }
    
    private func makeFetcher(for environment: ServerReceiptVerificationResponseDataFetcher.StoreEnvironment) -> ServerReceiptVerificationResponseDataFetcher {
        let fetcher = ServerReceiptVerificationResponseDataFetcher(verificationData: self.request.data, environment: environment, sharedSecret: self.sharedSecret)
        fetcher.onCompletion = { result in
            self.didFetchVerificationData(with: result)
        }
        
        return fetcher
    }
    
    private func didFetchVerificationData(with result: Result<Data>) {
        switch result {
            case .succeeded(let data):
                do {
                    let parser = ServerReceiptVerificationResponseParser() // this object handles the actual parsing of the data
                    let response = try parser.response(from: data)
                    let validatedReceipt = try parser.receipt(from: response)
                    
                    self.complete(with: .succeeded(validatedReceipt))
                } catch ServerReceiptVerificationResponseParser.ReceiptStatusError.receiptIncompatibleWithProductionEnvironment {
                    self.dataFetcher = self.makeFetcher(for: .sandbox)
                    self.dataFetcher.start()
                } catch let error {
                    self.complete(with: .failed(error))
                }
            case .failed(let error):
                self.complete(with: .failed(error))
        }
    }
}
