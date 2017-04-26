import StoreKit

internal class StoreKitReceiptDataFetcher : NSObject {
    var onCompletion: ((Result<Data>) -> Void)?
    var request: SKReceiptRefreshRequest?
    
    var fetchBehavior: FetchBehavior = .fetchElseRefresh
    
    override init() {
        super.init()
    }
    
    func start() {
        switch self.fetchBehavior {
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
    
    func cancel() {
        self.request?.cancel()
    }
    
    fileprivate func startRefreshRequest() {
        self.request = SKReceiptRefreshRequest()
        self.request?.delegate = self
        
        self.request?.start()
    }
    
    fileprivate func attemptFinishTaskFetchingLocalData(onFailure: () -> Void) {
        if let url = Bundle.main.appStoreReceiptURL, let data = try? Data(contentsOf: url) {
            self.finish(with: .succeeded(data))
        } else {
            onFailure()
        }
    }
    
    fileprivate func finish(with result: Result<Data>) {
        self.onCompletion?(result)
    }
    
    enum FetchBehavior {
        case alwaysRefresh
        case fetchElseRefresh
        case onlyFetch
    }
    
    enum Error : Swift.Error {
        case receiptUnavailableWithoutUserInteraction
    }
}

extension StoreKitReceiptDataFetcher : SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        self.attemptFinishTaskFetchingLocalData(onFailure: {
            fatalError("SKRequest inconsistency")
        })
    }
    
    func request(_ request: SKRequest, didFailWithError error: Swift.Error) {
        self.finish(with: .failed(error))
    }
}
