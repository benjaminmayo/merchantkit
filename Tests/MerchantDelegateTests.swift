import XCTest
@testable import MerchantKit

class MerchantDelegateTests : XCTestCase {
    func testConformance() {
        // dummy test case really - this test would fail to build at compile time, if required delegate methods were changed or renamed
        
        let merchant = Merchant(storage: EphemeralPurchaseStorage(), delegate: self)
        
        self.merchantDidChangeLoadingState(merchant) // this no-op is provided by the `MerchantDelegate` default implementation
    }
}

extension MerchantDelegateTests : MerchantDelegate {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
    
    func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        
    }
}
