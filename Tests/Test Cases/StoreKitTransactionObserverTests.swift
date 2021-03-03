import XCTest
import StoreKit
@testable import MerchantKit

class StoreKitTransactionObserverTests : XCTestCase {
    private var storeInterface: MockStoreInterface!
    private var storeInterfaceDelegate: MockStoreInterfaceDelegate!
    private var paymentQueue: MockSKPaymentQueue!
    private var transactionObserver: StoreKitTransactionObserver!
    
    override func setUp() {
        super.setUp()
        
        self.storeInterface = MockStoreInterface()
        self.storeInterfaceDelegate = MockStoreInterfaceDelegate()
        self.paymentQueue = MockSKPaymentQueue()
        
        self.transactionObserver = StoreKitTransactionObserver(storeInterface: self.storeInterface, paymentQueue: self.paymentQueue)
        self.transactionObserver.delegate = self.storeInterfaceDelegate
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.storeInterface = nil
        self.storeInterfaceDelegate = nil
        
        self.transactionObserver = nil
    }
    
    #if os(iOS)
    func testShouldAddStorePaymentReturnsConsistentResult() {
        let responsesAndExpectations: [(StoreIntentResponse, Bool)] = [
            (.automaticallyCommit, true),
            (.defer, false)
        ]
        
        let mockSKProduct = MockSKProduct(productIdentifier: "test", price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
        let mockSKPayment = MockSKPayment(product: mockSKProduct)
        
        for (response, expectation) in responsesAndExpectations {
            let completionExpectation = self.expectation(description: "Did request response.")

            self.storeInterfaceDelegate.responseForStoreIntentToCommit = { source in
                completionExpectation.fulfill()
                
                return response
            }
        
            let result = self.transactionObserver.paymentQueue(self.paymentQueue, shouldAddStorePayment: mockSKPayment, for: mockSKProduct)
            XCTAssertEqual(result, expectation, "The observer returned result \(result) when result \(expectation) was expected.")
            
            self.wait(for: [completionExpectation], timeout: 1)
        }
        
        self.storeInterfaceDelegate = nil
        
        let result = self.transactionObserver.paymentQueue(self.paymentQueue, shouldAddStorePayment: mockSKPayment, for: mockSKProduct)
        let expectedResult = true
        
        XCTAssertEqual(result, expectedResult, "Without a delegate set, the observer returned result \(result) when result \(expectedResult) was expected.")
    }
    #endif
    
    func testRestorePurchasesEventActivateDelegateCallbacks() {
        let eventAndExpectedResults: [(() -> Void, Result<Void, Error>)] = [
            ({ self.transactionObserver.paymentQueueRestoreCompletedTransactionsFinished(self.paymentQueue) }, .success),
            ({ self.transactionObserver.paymentQueue(self.paymentQueue, restoreCompletedTransactionsFailedWithError: MockError.mockError) }, .failure(MockError.mockError))
        ]
        
        for (event, expectedResult) in eventAndExpectedResults {
            let expectation = self.expectation(description: "Did finish restoring purchases.")
            
            self.storeInterfaceDelegate.didFinishRestoringPurchases = { result in
                switch (result, expectedResult) {
                    case (.success(_), .success(_)):
                        break
                    case (.failure(MockError.mockError), .failure(MockError.mockError)):
                        break
                    case (.success(_), .failure(let error)):
                        XCTFail("The callback succeeded when it was expected to fail with error \(error).")
                    case (.failure(let error), .failure(let expectedError)):
                        XCTFail("The callback failed with error \(error) when \(expectedError) was expected.")
                    case (.failure(let error), .success(_)):
                        XCTFail("The callback failed with error \(error) when it was expected to succeed.")
                }
                
                expectation.fulfill()
            }
            
            event()
            
            self.wait(for: [expectation], timeout: 1)
        }
    }
    
    func testUpdateTransactionsActivatesDelegateCallbacks() {
        let testProductIdentifier = "testProduct"
        
        let mockSKProduct = MockSKProduct(productIdentifier: testProductIdentifier, price: NSDecimalNumber(string: "1.00"), priceLocale: Locale(identifier: "en_US_POSIX"))
        let mockSKPayment = MockSKPayment(product: mockSKProduct)
        
        enum Processing {
            case didPurchase
            case didFail
            case didRestore
            case none
        }
        
        let transactionsAndExpectedProcessing: [(MockSKPaymentTransaction, Processing)] = [
            (MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: .purchased, error: nil, original: nil, payment: mockSKPayment), .didPurchase),
            (MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: .restored, error: nil, original: MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: .purchased, error: nil, original: nil, payment: mockSKPayment), payment: mockSKPayment), .didRestore),
            (MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: .failed, error: MockError.mockError, original: nil, payment: mockSKPayment), .didFail),
            (MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: .purchasing, error: nil, original: nil, payment: mockSKPayment), .none),
            (MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: .deferred, error: nil, original: nil, payment: mockSKPayment), .none),
            (MockSKPaymentTransaction(transactionIdentifier: testProductIdentifier, transactionState: SKPaymentTransactionState(rawValue: 92159124)! /* @unknown case test */, error: nil, original: nil, payment: mockSKPayment), .none)
        ]
        
        for (transaction, expectedProcessing) in  transactionsAndExpectedProcessing {
            func ensureExpectedProcessing(for processing: Processing, withProductIdentifier productIdentifier: String) {
                guard processing != expectedProcessing else { return }
            
                XCTAssertEqual(productIdentifier, testProductIdentifier, "The transaction was processed with product identifier \(productIdentifier) when \(testProductIdentifier) was expected.")
                XCTFail("The transaction was processed as \(processing) when \(expectedProcessing) was expected.")
            }
            
            let willUpdateExpectation = self.expectation(description: "Will update purchases.")
            let processedFailureOrPurchaseOrRestoreExpectation: XCTestExpectation? = expectedProcessing == .none ? nil : self.expectation(description: "Processed purchase or restore or failure.")
            let didUpdateExpectation = self.expectation(description: "Did update purchases.")
            
            self.storeInterfaceDelegate.willUpdatePurchases = {
                willUpdateExpectation.fulfill()
            }
            
            self.storeInterfaceDelegate.didPurchaseProduct = { (productIdentifier, completion) in
                ensureExpectedProcessing(for: .didPurchase, withProductIdentifier: productIdentifier)
                
                processedFailureOrPurchaseOrRestoreExpectation?.fulfill()
                
                completion()
            }
            
            self.storeInterfaceDelegate.didRestorePurchase = { productIdentifier in
                ensureExpectedProcessing(for: .didRestore, withProductIdentifier: productIdentifier)
                
                processedFailureOrPurchaseOrRestoreExpectation?.fulfill()
            }
            
            self.storeInterfaceDelegate.didFailToPurchase = { (productIdentifier, error) in
                ensureExpectedProcessing(for: .didFail, withProductIdentifier: productIdentifier)
                
                processedFailureOrPurchaseOrRestoreExpectation?.fulfill()
                
                switch error {
                    case MockError.mockError:
                        break
                    default:
                        XCTFail("The processing failed with error \(error) when \(MockError.mockError) was expected.")
                }
            }
            
            self.storeInterfaceDelegate.didUpdatePurchases = {
                didUpdateExpectation.fulfill()
            }
            
            DispatchQueue.main.async {
                self.transactionObserver.paymentQueue(self.paymentQueue, updatedTransactions: [transaction])
            }
            
            self.wait(for: [willUpdateExpectation, processedFailureOrPurchaseOrRestoreExpectation, didUpdateExpectation].compactMap { $0 }, timeout: 3, enforceOrder: true)
        }
    }
}
