import XCTest
import StoreKit
@testable import MerchantKit

class StoreKitStoreInterfaceTests : XCTestCase {
    private var storeInterface: StoreKitStoreInterface!
    
    private var availablePurchasesFetcher: AvailablePurchasesFetcher!
    
    override func setUp() {
        super.setUp()
    
        self.storeInterface = StoreKitStoreInterface()
        self.storeInterface.setup(withDelegate: self)
    }
    
    func testFetchAvailablePurchasesWithNonExistentProduct() {
        let completionExpectation = self.expectation(description: "Completed fetch available purchases.")
        let testProduct = self.availablePurchasesTestProduct
        
        let fetcher = self.storeInterface.makeAvailablePurchasesFetcher(for: [testProduct])
        fetcher.enqueueCompletion({ result in
            switch result {
                case .success(_):
                    XCTFail("The available purchases fetcher returned a success result when an error was expected.")
                case .failure(StoreKitAvailablePurchasesFetcher.Error.noAvailablePurchases(invalidProductIdentifiers: [testProduct.identifier])):
                    break
                case .failure(let error):
                    XCTFail("The available purchases fetcher failed with error \(error) when a failure with error \(StoreKitAvailablePurchasesFetcher.Error.noAvailablePurchases(invalidProductIdentifiers: [testProduct.identifier])) was expected.")
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
    
    func testCommitPurchase() {
        self.commitPurchaseTestProduct = self.makeCommitPurchaseTestProduct()
        self.commitPurchaseCompletionExpectation = self.expectation(description: "Completed commit purchase.")
        
        let skProduct = MockSKProduct(productIdentifier: self.commitPurchaseTestProduct.identifier, price: NSDecimalNumber(string: "1.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
        
        let purchase = Purchase(from: .availableProduct(skProduct), for: self.commitPurchaseTestProduct)
        self.storeInterface.commitPurchase(purchase, using: StoreParameters(applicationUsername: ""))
        
        self.wait(for: [self.commitPurchaseCompletionExpectation], timeout: 5)
    }
    
    private var commitPurchaseCompletionExpectation: XCTestExpectation!
    private var commitPurchaseTestProduct: Product!
}

extension StoreKitStoreInterfaceTests {
    private var availablePurchasesTestProduct: Product {
        return Product(identifier: "availablePurchasesTestProduct", kind: .nonConsumable)
    }
    
    private func makeCommitPurchaseTestProduct() -> Product {
        return Product(identifier: UUID().uuidString, kind: .nonConsumable)
    }
}

extension StoreKitStoreInterfaceTests : StoreInterfaceDelegate {
    func storeInterfaceWillUpdatePurchases(_ storeInterface: StoreInterface) {
        
    }
    
    func storeInterfaceDidUpdatePurchases(_ storeInterface: StoreInterface) {
        
    }
    
    func storeInterfaceWillStartRestoringPurchases(_ storeInterface: StoreInterface) {
        
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didFinishRestoringPurchasesWith result: Result<Void, Error>) {
        
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didPurchaseProductWith productIdentifier: String, completion: @escaping () -> Void) {
        if productIdentifier == self.commitPurchaseTestProduct.identifier {
            XCTFail("The commit purchase succeeded but was expected to fail.")
            
            self.commitPurchaseCompletionExpectation.fulfill()
        }
        
        completion()
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didFailToPurchaseProductWith productIdentifier: String, error: Error) {
        if productIdentifier == self.commitPurchaseTestProduct?.identifier {
            switch error {
                case SKError.unknown:
                    break
                case let error:
                    XCTFail("The commit purchase failed with error \(error) but was expected to fail with error \(SKError.unknown).")
            }
            
            self.commitPurchaseCompletionExpectation?.fulfill()
        }
    }
    
    func storeInterface(_ storeInterface: StoreInterface, didRestorePurchaseForProductWith productIdentifier: String) {
        
    }
    
    func storeInterface(_ storeInterface: StoreInterface, responseForStoreIntentToCommitPurchaseFrom source: Purchase.Source) -> StoreIntentResponse {
        return .default
    }
}
