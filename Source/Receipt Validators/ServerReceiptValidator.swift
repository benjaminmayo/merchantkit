/// Sends a request to the iTunes server for validation.
/// Attempts to make a validated receipt from the response and calls `onCompletion` when finished.
public final class ServerReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let request: ReceiptValidationRequest
    
    public var onCompletion: Completion?
    
    fileprivate let sharedSecret: String
    
    private var dataFetcher: ServerReceiptVerificationResponseDataFetcher!
    
    public init(request: ReceiptValidationRequest, sharedSecret: String) {
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
        fetcher.onCompletion = { [weak self] result in
            self?.didFetchVerificationData(with: result)
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
