import XCTest
@testable import MerchantKit

class ReceiptValidatorSubscriptionRenewalLeewayTests : XCTestCase {
    func testInitialization() {
        _ = ReceiptValidatorSubscriptionRenewalLeeway(allowedElapsedDuration: 0)
        _ = ReceiptValidatorSubscriptionRenewalLeeway(allowedElapsedDuration: 60)
        _ = ReceiptValidatorSubscriptionRenewalLeeway(allowedElapsedDuration: 60 * 60 * 24 * 100)
        
        let expectation = self.expectation(description: "Hit fatal error.")

        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        DispatchQueue.global(qos: .background).async {
            _ = ReceiptValidatorSubscriptionRenewalLeeway(allowedElapsedDuration: -1)
        }
        
        self.wait(for: [expectation], timeout: 5)
        
        MerchantKitFatalError.customHandler = nil
    }
}
