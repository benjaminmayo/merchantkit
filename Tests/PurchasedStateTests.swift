import XCTest
@testable import MerchantKit

class PurchasedStateTests : XCTestCase {
    func testIsPurchased() {
        XCTAssertTrue(PurchasedState.isSold.isPurchased)
        XCTAssertTrue(PurchasedState.isSubscribed(expiryDate: nil).isPurchased)
        
        XCTAssertFalse(PurchasedState.notPurchased.isPurchased)
        XCTAssertFalse(PurchasedState.unknown.isPurchased)
    }
}
