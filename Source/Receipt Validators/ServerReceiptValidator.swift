/// Sends a request to the iTunes server for validation.
/// Attempts to make a validated receipt from the response and calls `onCompletion` when finished.
<<<<<<< HEAD
public final class ServerReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let request: ReceiptValidationRequest
=======
public final class ServerReceiptValidator : ReceiptValidator {
    public typealias Completion = (Result<Receipt, Error>) -> Void
>>>>>>> c51c1d3... Conformed `ServerReceiptValidator` to `ReceiptValidator` protocol. Updated associated tests.
    
    private let sharedSecret: String?
    
    private var tasks = [ServerReceiptValidatorTask]()
    
    /// Create a new server-based validator for the `request`, with optional `sharedSecret`. This validator uses a network request to get a response from the iTunes receipt verification server.
    /// - Parameter request: The validation request vended by the `Merchant` in the `merchant(_:validate:completion:)` delegate callback.
    /// - Parameter sharedSecret: The shared secret is only used by the iTunes Store validation server for receipts that contain auto-renewable subscriptions. Therefore, this value is technically optional. However, attempts to validate receipts containing auto-renewing subscriptions will fail if this value is not provided.
    /// - Note: `sharedSecret` cannot be `nil` if the `Merchant` is managing auto-renewing subscription products.
    public init(sharedSecret: String?) {
        self.sharedSecret = sharedSecret
    }
    
    public func validate(_ request: ReceiptValidationRequest, completion: @escaping Completion) {
        let task = ServerReceiptValidatorTask(request: request, sharedSecret: self.sharedSecret)
        task.onCompletion = { result in
            completion(result)
            
            if let index = self.tasks.firstIndex(where: { $0 === task }) {
                self.tasks.remove(at: index)
            }
        }
        
        self.tasks.append(task)
        task.start()
    }
}

fileprivate class ServerReceiptValidatorTask {
    private let request: ReceiptValidationRequest
    private let sharedSecret: String?
    
    internal var onCompletion: ServerReceiptValidator.Completion!
    
    private var dataFetcher: ServerReceiptVerificationResponseDataFetcher!

    internal init(request: ReceiptValidationRequest, sharedSecret: String?) {
        self.request = request
        self.sharedSecret = sharedSecret
    }
    
    internal func start() {
        self.dataFetcher = self.makeFetcher(for: .production)
        self.dataFetcher.start()
    }
<<<<<<< HEAD
}

extension ServerReceiptValidator {
    private func complete(with result: Result<Receipt>) {
=======
    
    private func complete(with result: Result<Receipt, Error>) {
>>>>>>> c51c1d3... Conformed `ServerReceiptValidator` to `ReceiptValidator` protocol. Updated associated tests.
        self.onCompletion?(result)
    }
    
    private func makeFetcher(for environment: ServerReceiptVerificationResponseDataFetcher.StoreEnvironment) -> ServerReceiptVerificationResponseDataFetcher {
        let fetcher = ServerReceiptVerificationResponseDataFetcher(verificationData: self.request.data, environment: environment, sharedSecret: self.sharedSecret)
        fetcher.onCompletion = { result in
            self.didFetchVerificationData(with: result)
        }
        
        return fetcher
    }
    
<<<<<<< HEAD
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
=======
    private func didFetchVerificationData(with result: Result<Data, Error>) {
        let result: Result<Receipt, Error> = result.attemptMap { data in
            let parser = ServerReceiptVerificationResponseParser() // this object handles the actual parsing of the data
            let response = try parser.response(from: data)
            let validatedReceipt = try parser.receipt(from: response)
            
            return validatedReceipt
        }
        
        switch result {
        case .failure(ServerReceiptVerificationResponseParser.ReceiptStatusError.receiptIncompatibleWithProductionEnvironment):
            self.dataFetcher = self.makeFetcher(for: .sandbox)
            self.dataFetcher.start()
        default:
            self.complete(with: result)
>>>>>>> c51c1d3... Conformed `ServerReceiptValidator` to `ReceiptValidator` protocol. Updated associated tests.
        }
    }
}
