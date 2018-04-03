
public final class DebuggingStateTask : MerchantTask {
    public var onCompletion: TaskCompletion<DebuggingState>?
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    private let sharedSecret: String
    
    private var fetcher: ServerReceiptVerificationResponseDataFetcher?
    
    // Create a task using the `Merchant.debuggingReceiptStateTask(withSharedSecret:)` API.
    internal init(with merchant: Merchant, sharedSecret: String) {
        self.merchant = merchant
        self.sharedSecret = sharedSecret
    }
    
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.updateActiveTask(self)
        
        let fetcher = StoreKitReceiptDataFetcher(policy: .onlyFetch)
        fetcher.enqueueCompletion({ [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
                case .succeeded(let data):
                    strongSelf.startFetcher(with: data, for: .production)
                case .failed(let error):
                    strongSelf.finish(with: .failed(error))
            }
        })
        
        fetcher.start()
    }
    
    public struct DebuggingState {
        public let receiptJSON: [String : Any]
    }
}

extension DebuggingStateTask {
    private func finish(with result: Result<DebuggingState>) {
        self.onCompletion?(result)
        
        self.merchant.resignActiveTask(self)
        self.fetcher = nil
    }
    
    private func startFetcher(with data: Data, for environment: ServerReceiptVerificationResponseDataFetcher.StoreEnvironment) {
        let fetcher = ServerReceiptVerificationResponseDataFetcher(verificationData: data, environment: environment, sharedSecret: self.sharedSecret)
        fetcher.onCompletion = { [weak self] result in
            self?.didFinishFetching(with: result, from: data)
        }
        
        self.fetcher = fetcher
        fetcher.start()
    }
    
    private func didFinishFetching(with result: Result<Data>, from verificationData: Data) {
        switch result {
            case .succeeded(let data):
                do {
                    let parser = ServerReceiptVerificationResponseParser()
                    let response = try parser.response(from: data)
                    
                    switch response {
                        case .receiptJSON(let receiptJSON):
                            let debuggingState = DebuggingState(receiptJSON: receiptJSON)
                            self.finish(with: .succeeded(debuggingState))
                        case .verificationFailure(.receiptIncompatibleWithProductionEnvironment):
                            self.startFetcher(with: verificationData, for: .sandbox)
                        case .verificationFailure(let error):
                            self.finish(with: .failed(error))
                    }
                } catch let error {
                    self.finish(with: .failed(error))
                }
            case .failed(let error):
                self.finish(with: .failed(error))
        }
    }
}
