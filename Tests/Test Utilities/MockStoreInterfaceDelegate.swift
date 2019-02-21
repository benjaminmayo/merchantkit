@testable import MerchantKit

internal class MockStoreInterfaceDelegate {
    internal init() {
        
    }
    
    var willUpdatePurchases: (() -> Void)?
    var didUpdatePurchases: (() -> Void)?
    
    var willStartRestoringPurchases: (() -> Void)?
    var didFinishRestoringPurchases: ((Result<Void, Error>) -> Void)?
    var didPurchaseProduct: ((String, () -> Void) -> Void)?
    var didFailToPurchase: ((String, Error) -> Void)?
    var didRestorePurchase: ((String) -> Void)?
    var responseForStoreIntentToCommit: ((Purchase.Source) -> StoreIntentResponse)!
}

extension MockStoreInterfaceDelegate : StoreInterfaceDelegate {
    func storeInterfaceWillUpdatePurchases(_ storeInterface: StoreInterface) {
        self.willUpdatePurchases?()
    }
    
    func storeInterfaceDidUpdatePurchases(_ storeInterface: StoreInterface) {
        self.didUpdatePurchases?()
    }
    
    func storeInterfaceWillStartRestoringPurchases(_ storeInterface: StoreInterface) {
        self.willStartRestoringPurchases?()
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didFinishRestoringPurchasesWith result: Result<Void, Error>) {
        self.didFinishRestoringPurchases?(result)
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didPurchaseProductWith productIdentifier: String, completion: @escaping () -> Void) {
        if let didPurchaseProduct = self.didPurchaseProduct {
            didPurchaseProduct(productIdentifier, completion)
        } else {
            completion()
        }
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didFailToPurchaseProductWith productIdentifier: String, error: Error) {
        self.didFailToPurchase?(productIdentifier, error)
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didRestorePurchaseForProductWith productIdentifier: String) {
        self.didRestorePurchase?(productIdentifier)
    }
    
    func storeInterface(_ storeInterface: StoreInterface, responseForStoreIntentToCommitPurchaseFrom source: Purchase.Source) -> StoreIntentResponse {
        return self.responseForStoreIntentToCommit(source)
    }
}

