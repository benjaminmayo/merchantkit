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
        
        if !(testConfiguration.receiptValidator is TestingReceiptValidator) {
            XCTFail("`Merchant.Configuration.usefulForTestingAsPurchasedStateResetsOnApplicationLaunch` should use `TestingReceiptValidator`.")
        }
    }
    
    func testDefaultConfigurationFailsWithoutBundleIdentifier() {
        let failingImplementationClosure: @convention(c) (_ obj: NSObject, Selector) -> String? = { _, _ in
            return nil
        }
        
        let originalSelector = #selector(getter: Bundle.bundleIdentifier)
        
        let originalImplementation = class_getMethodImplementation(Bundle.self, originalSelector)!
        let method = class_getInstanceMethod(Bundle.self, originalSelector)!
        
        let failingImplementation = unsafeBitCast(failingImplementationClosure, to: IMP.self)
        
        method_setImplementation(method, failingImplementation)
        
        let expectation = self.expectation(description: "Hit fatal error.")

        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        DispatchQueue.global(qos: .background).async {
            let _ = Merchant.Configuration.default
        }
        
        self.wait(for: [expectation], timeout: 5)
        
        method_setImplementation(method, originalImplementation)
        MerchantKitFatalError.customHandler = nil
    }
}
