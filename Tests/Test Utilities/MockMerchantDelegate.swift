import MerchantKit

class MockMerchantDelegate : MerchantDelegate {
    var didChangeStates: ((_ products: Set<Product>) -> Void)?
    var didChangeLoadingState: (() -> Void)?
    
    init() {
        
    }
    
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        self.didChangeStates?(products)
    }
    
    func merchantDidChangeLoadingState(_ merchant: Merchant) {
        self.didChangeLoadingState?()
    }
}
