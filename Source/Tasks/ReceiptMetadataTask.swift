import Foundation

/// This task fetches receipt metadata that some app business logic may be interested in knowing.
/// In general, this task will be rarely used and many apps will not need to use it at all.
public final class ReceiptMetadataTask : MerchantTask {
    public var onCompletion: MerchantTaskCompletion<ReceiptMetadata>?
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    private var fetcher: ReceiptDataFetcher?
    
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
            let fetcher = self.merchant.storeInterface.makeReceiptFetcher(for: .onlyFetch)
            
            fetcher.enqueueCompletion { [weak self] fetchResult in
                let result = Result {
                    try LocalReceiptDataDecoder().decode(fetchResult.get()).metadata
                }
                
                
                self?.finish(with: result)
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
