import XCTest
import StoreKit
@testable import MerchantKit

class PurchaseSetTests : XCTestCase {
    func testEmpty() {
        let set = PurchaseSet(from: [])
        
        XCTAssertEqual(set.makeIterator().next(), nil)
    }
    
    func testSinglePurchase() {
        let testPurchase = Purchase(from: self.mockedProduct(forIdentifier: "test", price: "1.00"), characteristics: [])
        
        let purchaseSet = PurchaseSet(from: [testPurchase])
        
        let iterator = purchaseSet.makeIterator()
        let firstPurchase = iterator.next()
        let nonexistentPurchase = iterator.next()
        
        // set contains a purchase
        XCTAssertNotNil(firstPurchase)
        
        // set contains no more than one purchase
        XCTAssertNil(nonexistentPurchase)
        
        // contained purchase matches testPurchase
        XCTAssertEqual(firstPurchase!, testPurchase)
    }
    
    func testSinglePurchaseIdentity() {
        let testPurchase = Purchase(from: self.mockedProduct(forIdentifier: "test", price: "1.00"), characteristics: [])
        
        let purchaseSet = PurchaseSet(from: [testPurchase, testPurchase])
        
        let iterator = purchaseSet.makeIterator()
        let firstPurchase = iterator.next()
        let nonexistentPurchase = iterator.next()
        
        // set contains a purchase
        XCTAssertNotNil(firstPurchase)
        
        // set contains no more than one purchase
        XCTAssertNil(nonexistentPurchase)
        
        // contained purchase matches testPurchase
        XCTAssertEqual(firstPurchase!, testPurchase)
    }
    
    func testMultiplePurchases() {
        let testPurchase = Purchase(from: self.mockedProduct(forIdentifier: "test", price: "1.00"), characteristics: [])
        let differentTestPurchase = Purchase(from: self.mockedProduct(forIdentifier: "test2", price: "2.00"), characteristics: [])
        
        let purchaseSet = PurchaseSet(from: [testPurchase, differentTestPurchase])
        
        let iterator = purchaseSet.makeIterator()
        let firstPurchase = iterator.next()
        let secondPurchase = iterator.next()
        
        // set contains a purchase
        XCTAssertNotNil(firstPurchase)
        
        // set contains another purchase
        XCTAssertNotNil(secondPurchase)
        
        // found purchases are not the same
        XCTAssertNotEqual(firstPurchase!, secondPurchase!)
        
        // firstPurchase is either of the two test purchases
        XCTAssertTrue(firstPurchase == testPurchase || firstPurchase == differentTestPurchase)
        
        // secondPurchase is either of the two test purchases
        XCTAssertTrue(secondPurchase == testPurchase || secondPurchase == differentTestPurchase)
    }
    
    func testSortingPurchases() {
        let cheapestPurchase = Purchase(from: self.mockedProduct(forIdentifier: "1", price: "1.00"), characteristics: [])
        let mediumPricedPurchase = Purchase(from: self.mockedProduct(forIdentifier: "2", price: "2.00"), characteristics: [])
        let mostExpensivePurchase = Purchase(from: self.mockedProduct(forIdentifier: "3", price: "3.00"), characteristics: [])
        
        let set = PurchaseSet(from: [cheapestPurchase, mediumPricedPurchase, mostExpensivePurchase])
        
        let sortedAscending = set.sortedByPrice(ascending: true)
        let expectedAscending = [cheapestPurchase, mediumPricedPurchase, mostExpensivePurchase]
        
        // sorted array is in correct ascending order
        XCTAssertEqual(sortedAscending, expectedAscending)
        
        let sortedDescending = set.sortedByPrice(ascending: false)
        let expectedDescending = [mostExpensivePurchase, mediumPricedPurchase, cheapestPurchase]
        
        // sorted array is in correct descending order
        XCTAssertEqual(sortedDescending, expectedDescending)
    }
    
    func testAccessor() {
        let productForMockedProduct = Product(identifier: "test", kind: .nonConsumable)
        let testPurchase = Purchase(from: self.mockedProduct(forIdentifier: "test", price: "1.00"), characteristics: [])
        
        let purchaseSet = PurchaseSet(from: [testPurchase])
        
        let purchase = purchaseSet.purchase(for: productForMockedProduct)
        
        // set finds the correct purchase
        XCTAssertEqual(purchase, testPurchase)
    }
    
    private func mockedProduct(forIdentifier productIdentifier: String, price: String) -> SKProduct {
        let price = NSDecimalNumber(string: price)
        let locale = Locale(identifier: "en_US_POSIX")
        
        let mockProduct = MockSKProduct(productIdentifier: productIdentifier, price: price, priceLocale: locale)
        
        return mockProduct
    }
}

class MockSKProduct : SKProduct {
    private let _productIdentifier: String
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    
    init(productIdentifier: String, price: NSDecimalNumber, priceLocale: Locale) {
        self._productIdentifier = productIdentifier
        self._price = price
        self._priceLocale = priceLocale
    }
    
    override var productIdentifier: String {
        return self._productIdentifier
    }
    
    override var price: NSDecimalNumber {
        return self._price
    }
    
    override var priceLocale: Locale {
        return self._priceLocale
    }
}
