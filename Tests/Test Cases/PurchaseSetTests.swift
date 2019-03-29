import XCTest
import Foundation
import StoreKit
@testable import MerchantKit

class PurchaseSetTests : XCTestCase {
    func testEmpty() {
        let set = PurchaseSet(from: [])
        
        XCTAssertEqual(set.makeIterator().next(), nil)
    }
    
    func testSinglePurchase() {
        let testPurchase = self.mockPurchase(forIdentifier: "test", price: "1.00")
        
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
        let testPurchase = self.mockPurchase(forIdentifier: "test", price: "1.00")
        
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
        let testPurchase = self.mockPurchase(forIdentifier: "test", price: "1.00")
        let differentTestPurchase = self.mockPurchase(forIdentifier: "test2", price: "2.00")
        
        let purchaseSet = PurchaseSet(from: [testPurchase, differentTestPurchase])
        
        // set reports `underestimatedCount` of Sequence as if it was a `count` of product identifiers
        XCTAssertEqual(purchaseSet.underestimatedCount, 2)
        
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
        let cheapestPurchase = self.mockPurchase(forIdentifier: "1", price: "1.00")
        let mediumPricedPurchase = self.mockPurchase(forIdentifier: "2", price: "2.00")
        let mostExpensivePurchase = self.mockPurchase(forIdentifier: "3", price: "3.00")
        
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
        let testPurchase = self.mockPurchase(forIdentifier: "test", price: "1.00")
        
        let purchaseSet = PurchaseSet(from: [testPurchase])
        
        let purchase = purchaseSet.purchase(for: productForMockedProduct)
        
        // set finds the correct purchase
        XCTAssertEqual(purchase, testPurchase)
    }
    
    private func mockPurchase(forIdentifier productIdentifier: String, price: String) -> Purchase {
        let product = Product(identifier: productIdentifier, kind: .nonConsumable)

        let price = NSDecimalNumber(string: price)
        let locale = Locale(identifier: "en_US_POSIX")
        
        let mockSKProduct = MockSKProduct(productIdentifier: productIdentifier, price: price, priceLocale: locale)
        
        return Purchase(from: .availableProduct(mockSKProduct), for: product)
    }
}
