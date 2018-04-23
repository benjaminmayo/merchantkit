import XCTest
import Foundation 
@testable import MerchantKit

class PurchasedStateTests : XCTestCase {
    func testIsPurchased() {
        let dummyProductInfo = PurchasedProductInfo(expiryDate: nil)
        
        XCTAssertTrue(PurchasedState.isPurchased(dummyProductInfo).isPurchased)
        
        XCTAssertFalse(PurchasedState.notPurchased.isPurchased)
        XCTAssertFalse(PurchasedState.unknown.isPurchased)
    }
}
