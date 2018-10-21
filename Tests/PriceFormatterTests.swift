import XCTest
import Foundation
@testable import MerchantKit

class PriceFormatterTests : XCTestCase {
    func testDefaultsInUSEnglish() {
        let formatter = PriceFormatter()
        
        let testingPrice = Price(value: (Decimal(string: "1.99")!, Locale(identifier: "en-US")))
        
        let formattedString = formatter.string(from: testingPrice)
        
        XCTAssertEqual(formattedString, "$1.99")
    }
    
    func testDefaultsInUKEnglish() {
        let formatter = PriceFormatter()
        
        let testingPrice = Price(value: (Decimal(string: "9.99")!, Locale(identifier: "en-GB")))
        
        let formattedString = formatter.string(from: testingPrice)
        
        XCTAssertEqual(formattedString, "£9.99")
    }
    
    func testSuffixInUSEnglish() {
        let formatter = PriceFormatter()
        formatter.suffix = " with suffix"
        
        let testingPrice = Price(value: (Decimal(string: "1.99")!, Locale(identifier: "en-US")))
        
        let formattedString = formatter.string(from: testingPrice)
        
        XCTAssertEqual(formattedString, "$1.99 with suffix")
    }
    
    func testFreePrice() {
        let formatter = PriceFormatter()
        formatter.freeReplacementText = "FREE"
        
        let freePrice = Price(value: (Decimal(string: "0")!, Locale(identifier: "en-US")))
        
        let formattedString = formatter.string(from: freePrice)
        
        XCTAssertEqual(formattedString, "FREE")
    }
}
