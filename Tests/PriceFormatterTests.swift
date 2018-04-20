import XCTest
import Foundation
@testable import MerchantKit

class PriceFormatterTests : XCTestCase {
    func testDefaultsInUSEnglish() {
        let formatter = PriceFormatter()
        
        let testingPrice = Price(from: NSDecimalNumber(string: "1.99"), in: Locale(identifier: "en-US"))
        
        let formattedString = formatter.string(from: testingPrice)
        
        XCTAssertEqual(formattedString, "$1.99")
    }
    
    func testDefaultsInUKEnglish() {
        let formatter = PriceFormatter()
        
        let testingPrice = Price(from: NSDecimalNumber(string: "9.99"), in: Locale(identifier: "en-GB"))
        
        let formattedString = formatter.string(from: testingPrice)
        
        XCTAssertEqual(formattedString, "£9.99")
    }
    
    func testSuffixInUSEnglish() {
        let formatter = PriceFormatter()
        formatter.suffix = " with suffix"
        
        let testingPrice = Price(from: NSDecimalNumber(string: "1.99"), in: Locale(identifier: "en-US"))
        
        let formattedString = formatter.string(from: testingPrice)
        
        XCTAssertEqual(formattedString, "$1.99 with suffix")
    }
    
    func testFreePrice() {
        let formatter = PriceFormatter()
        formatter.freeReplacementText = "FREE"
        
        let freePrice = Price(from: NSDecimalNumber(string: "0"), in: Locale(identifier: "en-US"))
        
        let formattedString = formatter.string(from: freePrice)
        
        XCTAssertEqual(formattedString, "FREE")
    }
}
