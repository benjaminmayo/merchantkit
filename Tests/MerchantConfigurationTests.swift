import XCTest
import Foundation
@testable import MerchantKit

class MerchantConfigurationTests : XCTestCase {
    func testDefaultConfiguration() {
        let defaultConfiguration = Merchant.Configuration.default
        
        if !(defaultConfiguration.storage is KeychainPurchaseStorage) {
            XCTFail("`Merchant.Configuration.default` should use `KeychainPurchaseStorage`.")
        }
        
        if !(defaultConfiguration.receiptValidator is LocalReceiptValidator) {
            XCTFail("`Merchant.Configuration.default` should use `LocalReceiptValidator`.")
        }
    }
    
    func testEphemeralConfiguration() {
        let testConfiguration = Merchant.Configuration.usefulForTestingAsPurchasedStateResetsOnApplicationLaunch
        
        if !(testConfiguration.storage is EphemeralPurchaseStorage) {
            XCTFail("`Merchant.Configuration.usefulForTestingAsPurchasedStateResetsOnApplicationLaunch` should use `EphemeralPurchaseStorage`.")
        }
    }
}
