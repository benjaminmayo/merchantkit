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
    
    /// Start the task to begin fetching receipt metadata.
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        
        DispatchQueue.main.async {
            self.merchant.taskDidStart(self)
        }
        
        self.merchant.logger.log(message: "Started fetching receipt metadata", category: .tasks)
        
        if let receipt = self.merchant.latestFetchedReceipt {
            self.finish(with: .success(receipt.metadata))
        } else {
            let fetcher = StoreKitReceiptDataFetcher(policy: .onlyFetch)
            
            fetcher.enqueueCompletion { [weak self] result in
                switch result {
                    case .success(let data):
                        let request = ReceiptValidationRequest(data: data, reason: .initialization)
                        let validator = LocalReceiptValidator() // use LocalReceiptValidator concretely; we do not want to use the validator from the `Merchant.Configuration` here.
                        validator.validate(request, completion: { [weak self] result in
                            switch result {
                                case .success(let receipt):
                                    self?.finish(with: .success(receipt.metadata))
                                case .failure(let error):
                                    self?.finish(with: .failure(error))
                            }
                        })
                    case .failure(let error):
                        self?.finish(with: .failure(error))
                }
            }
            
            fetcher.start()
            
            self.fetcher = fetcher
        }
    }
}

extension ReceiptMetadataTask {
    private func finish(with result: Result<ReceiptMetadata, Error>) {
        self.onCompletion?(result)
        
        self.merchant.logger.log(message: "Finished fetching receipt metadata: \(result)", category: .tasks)
        
        self.fetcher = nil
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
    }
}
