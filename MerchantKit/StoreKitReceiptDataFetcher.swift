import StoreKit

internal class StoreKitReceiptDataFetcher : NSObject {
    var onCompletion: ((Result<Data>) -> Void)?
    var request: SKReceiptRefreshRequest!
    
    override init() {
        super.init()
    }
    
    func start() {
        self.attemptFinishTaskFetchingLocalData(onFailure: {
            self.request = SKReceiptRefreshRequest()
            self.request.delegate = self
            
            self.request.start()
        })
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
}

extension StoreKitReceiptDataFetcher : SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        self.attemptFinishTaskFetchingLocalData(onFailure: {
            fatalError("SKRequest inconsistency")
        })
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(with: .failed(error))
    }
}
