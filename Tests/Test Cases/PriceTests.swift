import XCTest
import Foundation
@testable import MerchantKit

class PriceTests : XCTestCase {
    func testEquality() {
        let decimal: Decimal = 1.00
        
        let locale = Locale(identifier: "en_US_POSIX")
        
        let price = Price(value: Price.Value(decimal, locale))
        
        let anotherSamePrice = Price(value: Price.Value(decimal, locale))
        
        XCTAssertEqual(price, anotherSamePrice)
    }
    
    func testHashable() {
        let decimal: Decimal = 1.00
        let anotherDecimal: Decimal = 2.50

        let locale = Locale(identifier: "en_US_POSIX")
        
        let price = Price(value: Price.Value(decimal, locale))
        let anotherPrice = Price(value: Price.Value(anotherDecimal, locale))

        var priceSet = Set<Price>()
        priceSet.insert(price)
        priceSet.insert(anotherPrice)
        priceSet.insert(price)
        
        XCTAssertEqual(priceSet.count, 2)
    }
}
