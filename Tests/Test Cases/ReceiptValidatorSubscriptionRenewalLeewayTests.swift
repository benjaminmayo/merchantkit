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
    
    func testMerchantRespectsLeewayDuration() {
        let interval: TimeInterval = (60 * 60 * 24)
        let maximum = 100
        
        for index in 0..<(maximum/2) {
            let entries = (0..<maximum).map { index in
                ReceiptEntry(productIdentifier: "\(index)", expiryDate: Date().addingTimeInterval(-TimeInterval(index) * interval))
            }
            
            let mockValidator = MockReceiptValidator()
            mockValidator.validateRequest = { (_, completion) in
                let receipt = ConstructedReceipt(from: entries, metadata: .init(originalApplicationVersion: "1", bundleIdentifier: "", creationDate: Date()))

                completion(.success(receipt))
            }

            let products = entries.map({ $0.productIdentifier }).map { productIdentifier in
                Product(identifier: productIdentifier, kind: .subscription(automaticallyRenews: true))
            }
            
            let expectation = self.expectation(description: "expected unlocked subscription for products up to index \(index)")
            expectation.expectedFulfillmentCount = index + 1
            expectation.assertForOverFulfill = true
            mockValidator.subscriptionRenewalLeeway = .init(allowedElapsedDuration: 1.0 + (TimeInterval(index) * interval))
            
            let mockStoreInterface = MockStoreInterface()
            mockStoreInterface.receiptFetchResult = .success(Data())
            
            var subscribedProducts = Set(products[0...index])

            var merchant: Merchant!
            let mockDelegate = MockMerchantDelegate()
            mockDelegate.didChangeStates = { products in
                for product in products where merchant.state(for: product).isPurchased {
                    if subscribedProducts.remove(product) != nil {
                        expectation.fulfill()
                    }
                }
            }
            
            let configuration = Merchant.Configuration(receiptValidator: mockValidator, storage: EphemeralPurchaseStorage())
            merchant = Merchant(configuration: configuration, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
            
            merchant.register(products)
            merchant.setup()
            
            self.wait(for: [expectation], timeout: 5)
        }
    }
}
