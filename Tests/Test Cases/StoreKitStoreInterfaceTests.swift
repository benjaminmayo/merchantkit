import XCTest
import StoreKit
@testable import MerchantKit

class StoreKitStoreInterfaceTests : XCTestCase {
    private var storeInterface: StoreKitStoreInterface!
    private var storeInterfaceDelegate: MockStoreInterfaceDelegate!
    
    private var availablePurchasesFetcher: AvailablePurchasesFetcher!
    
    override func setUp() {
        super.setUp()
        
        self.storeInterfaceDelegate = MockStoreInterfaceDelegate()

        self.storeInterface = StoreKitStoreInterface(paymentQueue: .default())
        self.storeInterface.setup(withDelegate: self.storeInterfaceDelegate)
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.storeInterface = nil
        self.storeInterfaceDelegate = nil
    }
    
    func testFetchAvailablePurchasesWithNonExistentProduct() {
        let testProduct = Product(identifier: "availablePurchasesTestProduct", kind: .nonConsumable)

        let completionExpectation = self.expectation(description: "Completed fetch available purchases.")

        let fetcher = self.storeInterface.makeAvailablePurchasesFetcher(for: [testProduct])
        fetcher.enqueueCompletion({ result in
            switch result {
                case .success(_):
                    XCTFail("The available purchases fetcher returned a success result when an error was expected.")
                case .failure(AvailablePurchasesFetcherError.noAvailablePurchases(invalidProducts: [testProduct])):
                    break
                case .failure(let error):
                    #if os(macOS) // macOS returns a generic unknown error here
                    if case .other(SKError.unknown) = error {
                        break
                    }
                    #endif
                    
                    XCTFail("The available purchases fetcher failed with error \(error) when a failure with error \(AvailablePurchasesFetcherError.noAvailablePurchases(invalidProducts: [testProduct])) was expected.")
            }
            
            completionExpectation.fulfill()
        })
        
        fetcher.start()
        
        self.availablePurchasesFetcher = fetcher
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testFetchAvailablePurchasesWithEmptyProductSet() {
        let completionExpectation = self.expectation(description: "Completed available purchase fetch.")
        
        let fetcher = self.storeInterface.makeAvailablePurchasesFetcher(for: [])
        fetcher.enqueueCompletion({ result in
            switch result {
                case .success(PurchaseSet(from: [])):
                    break
                case .success(let otherSet):
                    XCTFail("The available purchases fetcher succeeded with \(otherSet) when it was expected to succeed with \(PurchaseSet(from: [])).")
                case .failure(let error):
                    XCTFail("The available purchases fetcher failed with error \(error) when it was expected to succeed.")
            }
            
            completionExpectation.fulfill()
        })
        
        fetcher.start()
        
        self.availablePurchasesFetcher = fetcher
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testFetchAvailablePurchasesWithCancellation() {
        let completionExpectation = self.expectation(description: "Completed available purchase fetch.")
        completionExpectation.isInverted = true
        
        let fetcher = self.storeInterface.makeAvailablePurchasesFetcher(for: [])
        fetcher.enqueueCompletion({ result in
            completionExpectation.fulfill()
        })
        
        fetcher.start()
        
        fetcher.cancel()
        
        self.availablePurchasesFetcher = fetcher
        
        self.wait(for: [completionExpectation], timeout: 5)
    }

    func testFetchReceiptData() {
        let completionExpectation = self.expectation(description: "Completed fetch receipt.")
        
        let fetcher = self.storeInterface.makeReceiptFetcher(for: .onlyFetch)
        fetcher.enqueueCompletion({ result in
            switch result {
                case .success(let data):
                    XCTFail("The receipt fetch succeeded with data \(data) when it was expected to fail.")
                case .failure(ReceiptFetchError.receiptUnavailableWithoutRefresh):
                    break
                case .failure(let error):
                    XCTFail("The receipt fetch failed with \(error) when it was expected to fail with error \(ReceiptFetchError.receiptUnavailableWithoutRefresh).")
            }
                
            completionExpectation.fulfill()
        })
            
        fetcher.start()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testRestorePurchases() {
        self.storeInterface.restorePurchases(using: StoreParameters(applicationUsername: ""))
    }
    
//    #if os(iOS)
//    func testCommitPurchase() {
//        let testProduct = self.makeCommitPurchaseTestProduct()
//
//        let mockSKProduct = MockSKProduct(productIdentifier: testProduct.identifier, price: NSDecimalNumber(string: "1.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
//        let mockSKPayment = MockSKPayment(product: mockSKProduct)
//
//        let purchaseSources: [Purchase.Source] = [
//            .availableProduct(mockSKProduct),
//            .pendingStorePayment(mockSKProduct, mockSKPayment)
//        ]
//
//        let completionExpectation = self.expectation(description: "Completed commit purchase.")
//        completionExpectation.expectedFulfillmentCount = purchaseSources.count
//
//        self.storeInterfaceDelegate.didPurchaseProduct = { productIdentifier, completion in
//            if productIdentifier == testProduct.identifier {
//                XCTFail("The commit purchase succeeded but was expected to fail.")
//
//                completionExpectation.fulfill()
//            }
//
//            completion()
//        }
//
//        self.storeInterfaceDelegate.didFailToPurchase = { productIdentifier, error in
//            if productIdentifier == testProduct.identifier {
//                switch error {
//                    case SKError.unknown:
//                        break
//                    case let error:
//                        XCTFail("The commit purchase failed with error \(error) but was expected to fail with error \(SKError.unknown).")
//                }
//
//                completionExpectation.fulfill()
//            }
//        }
//
//        for source in purchaseSources {
//            let purchase = Purchase(from: source, for: testProduct)
//
//            self.storeInterface.commitPurchase(purchase, with: nil, using: StoreParameters(applicationUsername: ""))
//        }
//
//        self.wait(for: [completionExpectation], timeout: 5)
//    }
//    #endif
}

extension StoreKitStoreInterfaceTests {
    private func makeCommitPurchaseTestProduct() -> Product {
        return Product(identifier: UUID().uuidString, kind: .nonConsumable)
    }
}
