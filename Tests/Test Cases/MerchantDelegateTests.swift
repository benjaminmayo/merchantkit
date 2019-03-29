import XCTest
@testable import MerchantKit

class MerchantDelegateTests : XCTestCase {
    func testConformance() { // this just ensures we didn't forget any default implementations
        let mockStoreInterface = MockStoreInterface()

        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: self, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true

        self.merchant(merchant, didChangeStatesFor: [])
        self.merchantDidChangeLoadingState(merchant)
        _ = self.merchant(merchant, didReceiveStoreIntentToCommit: self.testPurchase)
    }
    
    func testDefaultStoreIntent() {
        let mockStoreInterface = MockStoreInterface()
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: self, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true

        let result = self.merchant(merchant, didReceiveStoreIntentToCommit: self.testPurchase)
        
        XCTAssertEqual(result, .automaticallyCommit)
    }
}

extension MerchantDelegateTests : MerchantDelegate {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
}

extension MerchantDelegateTests {
    private var testPurchase: Purchase {
        return Purchase(from: .availableProduct(MockSKProduct(productIdentifier: "", price: NSDecimalNumber(string: ""), priceLocale: .init(identifier: "en_US_POSIX"))), for: Product(identifier: "", kind: .nonConsumable))
    }
}
