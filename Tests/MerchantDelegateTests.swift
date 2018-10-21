import XCTest
@testable import MerchantKit

class MerchantDelegateTests : XCTestCase {
    func testConformance() {
        // dummy test case really - this test would fail to build at compile time, if required delegate methods were changed or renamed
        
        let merchant = Merchant(storage: EphemeralPurchaseStorage(), delegate: self)
        
        self.merchantDidChangeLoadingState(merchant) // this no-op is provided by the `MerchantDelegate` default implementation
    }
    
    func testConsumeProductTrappingDefaultImplementation() {
        let expectation = self.expectation(description: "fatalError thrown")
        
        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        let consumableProduct = Product(identifier: "testProduct", kind: .consumable)
        
        let testingQueue = DispatchQueue(label: "testing queue") // testing MerchantKitFatalError requires dispatch to a non-main thread
        
        testingQueue.async {
            let merchant = Merchant(storage: EphemeralPurchaseStorage(), delegate: self)
            self.merchant(merchant, consume: consumableProduct, completion: {})
        }
        
        self.wait(for: [expectation], timeout: 1)
    }
}

extension MerchantDelegateTests : MerchantDelegate {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
    
    func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        
    }
}
