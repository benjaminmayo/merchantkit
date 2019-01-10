/// This task fetches receipt metadata that some app business logic may be interested in knowing.
/// In general, this task will be rarely used and many apps will not need to use it at all.
public final class ReceiptMetadataTask : MerchantTask {
    public var onCompletion: TaskCompletion<ReceiptMetadata>?
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    private var fetcher: StoreKitReceiptDataFetcher?
    
    /// Create a task using the `Merchant.receiptMetadataTask()` API.
    internal init(with merchant: Merchant) {
        self.merchant = merchant
    }
    
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.updateActiveTask(self)
        
        self.merchant.logger.log(message: "Started fetching receipt metadata", category: .tasks)
        
        if let receipt = self.merchant.latestFetchedReceipt {
            self.finish(with: .succeeded(receipt.metadata))
        } else {
            let fetcher = StoreKitReceiptDataFetcher(policy: .onlyFetch)
            
            fetcher.enqueueCompletion { [weak self] result in
                switch result {
                    case .succeeded(let data):
                        let request = ReceiptValidationRequest(data: data, reason: .initialization)
                        let validator = LocalReceiptValidator(request: request)
                        validator.onCompletion = { [weak self] result in
                            switch result {
                                case .succeeded(let receipt):
                                    self?.finish(with: .succeeded(receipt.metadata))
                                case .failed(let error):
                                    self?.finish(with: .failed(error))
                            }
                        }
                        
                        validator.start()
                    case .failed(let error):
                        self?.finish(with: .failed(error))
                }
            }
            
            fetcher.start()
            
            self.fetcher = fetcher
        }
    }
}

extension ReceiptMetadataTask {
    private func finish(with result: Result<ReceiptMetadata>) {
        self.onCompletion?(result)
        
        self.merchant.logger.log(message: "Finished fetching receipt metadata: \(result)", category: .tasks)
        
        self.fetcher = nil
        
        DispatchQueue.main.async {
            self.merchant.resignActiveTask(self)
        }
    }
}
