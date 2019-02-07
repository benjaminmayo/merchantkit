import XCTest
import Foundation
@testable import MerchantKit

class MerchantConfigurationTests : XCTestCase {
    func testDefaultConfiguration() {
        let defaultConfiguration = Merchant.Configuration.default(withServiceName: "test")
        
        if !(defaultConfiguration.storage is KeychainPurchaseStorage) {
            XCTFail("`Merchant.Configuration.default` should use `KeychainPurchaseStorage`.")
        }
        
        if !(defaultConfiguration.receiptValidator is LocalReceiptValidator) {
            XCTFail("`Merchant.Configuration.default` should use `LocalReceiptValidator`.")
        }
    }
}
