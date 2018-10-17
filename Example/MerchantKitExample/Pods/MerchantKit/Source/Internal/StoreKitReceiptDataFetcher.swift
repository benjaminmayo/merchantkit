import Foundation 
import StoreKit

internal final class StoreKitReceiptDataFetcher : NSObject, ReceiptDataFetcher {
    typealias Completion = ((Result<Data>) -> Void)
    
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
                    self.finish(with: .failed(Error.receiptUnavailableWithoutUserInteraction))
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
    
    enum Error : Swift.Error, LocalizedError {
        case receiptUnavailableWithoutUserInteraction
        
        var localizedDescription: String {
            return "Receipt unavailable without user interaction."
        }
    }
}

extension StoreKitReceiptDataFetcher {
    private func startRefreshRequest() {
        self.request = SKReceiptRefreshRequest()
        self.request?.delegate = self
        
        self.request?.start()
    }
    
    private func attemptFinishTaskFetchingLocalData(onFailure: () -> Void) {
        if let url = Bundle.main.appStoreReceiptURL, let data = try? Data(contentsOf: url) {
            self.finish(with: .succeeded(data))
        } else {
            onFailure()
        }
    }
    
    private func finish(with result: Result<Data>) {
        for completion in self.completionHandlers {
            completion(result)
        }
        
        self.isFinished = true
    }
}

extension StoreKitReceiptDataFetcher : SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        self.attemptFinishTaskFetchingLocalData(onFailure: {
            MerchantKitFatalError.raise("SKRequest inconsistency")
        })
    }
    
    func request(_ request: SKRequest, didFailWithError error: Swift.Error) {
        self.finish(with: .failed(error))
    }
}
