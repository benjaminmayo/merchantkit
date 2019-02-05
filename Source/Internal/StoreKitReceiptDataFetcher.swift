import Foundation 
import StoreKit

internal final class StoreKitReceiptDataFetcher : NSObject, ReceiptDataFetcher {
    typealias Completion = ((Result<Data, Error>) -> Void)
    
    internal let policy: ReceiptFetchPolicy

    private var completionHandlers = [Completion]()
    
    private var request: SKReceiptRefreshRequest?
    
    private(set) var isFinished: Bool = false
    
    init(policy: ReceiptFetchPolicy) {
        self.policy = policy
        
        super.init()
    }
    
    func start() {
        switch self.policy {
            case .alwaysRefresh:
                self.startRefreshRequest()
            case .fetchElseRefresh:
                self.attemptFinishTaskFetchingLocalData(onFailure: {
                    self.startRefreshRequest()
                })
            case .onlyFetch:
                self.attemptFinishTaskFetchingLocalData(onFailure: {
                    self.finish(with: .failure(ReceiptFetchError.receiptUnavailableWithoutRefresh))
                })
        }
    }
    
    func enqueueCompletion(_ completion: @escaping Completion) {
        assert(!self.isFinished, "completion blocks cannot be added after the fetcher is finished")
        
        self.completionHandlers.append(completion)
    }
    
    func cancel() {
        self.request?.cancel()
        self.isFinished = true
    }
}

extension StoreKitReceiptDataFetcher {
    private func startRefreshRequest() {
        self.request = SKReceiptRefreshRequest()
        self.request?.delegate = self
        
        self.request?.start()
    }
    
    private func attemptFinishTaskFetchingLocalData(onFailure: () -> Void) {
        if let url = Bundle.main.appStoreReceiptURL, let isReachable = try? url.checkResourceIsReachable(), isReachable == true, let data = try? Data(contentsOf: url) {
            self.finish(with: .success(data))
        } else {
            onFailure()
        }
    }
    
    private func finish(with result: Result<Data, Error>) {
        for completion in self.completionHandlers {
            completion(result)
        }
        
        self.isFinished = true
    }
}

extension StoreKitReceiptDataFetcher : SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        self.attemptFinishTaskFetchingLocalData(onFailure: {
            MerchantKitFatalError.raise("`SKReceiptRefreshRequest` did not behave as expected. Receipt data was not found after refreshing the receipt successfully.")
        })
    }
    
    func request(_ request: SKRequest, didFailWithError error: Swift.Error) {
        self.finish(with: .failure(error))
    }
}
