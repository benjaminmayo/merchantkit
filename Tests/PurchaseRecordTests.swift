import XCTest
import Foundation
@testable import MerchantKit

class PurchaseRecordTests : XCTestCase {
    func testConversionToDictNoExpiryDate() {
        let record = PurchaseRecord(productIdentifier: "productIdentifier", expiryDate: nil)
        
        let dict = record.dictionaryRepresentation
        let convertedRecord = PurchaseRecord(from: dict)
        
        XCTAssertEqual(record, convertedRecord)
    }
    
    func testConversionToDictWithExpiryDate() {
        let record = PurchaseRecord(productIdentifier: "productIdentifier", expiryDate: Date())
        
        let dict = record.dictionaryRepresentation
        let convertedRecord = PurchaseRecord(from: dict)
        
        XCTAssertEqual(record, convertedRecord)
    }
    
    func testConversionFromDictNoExpiryDate() {
        let productIdentifier = "productIdentifier"
        let dict = ["productIdentifier" : productIdentifier]
        
        guard let record = PurchaseRecord(from: dict) else { XCTFail("purchase record not created"); return; }
        
        XCTAssertEqual(record.productIdentifier, productIdentifier)
    }
    
    func testConversionFromDictWithExpiryDate() {
        let productIdentifier = "productIdentifier"
        let expiryDate = Date()
        let dict = ["productIdentifier" : productIdentifier, "expiryDate" : expiryDate] as [String : Any]
        
        guard let record = PurchaseRecord(from: dict) else { XCTFail("purchase record not created"); return; }
        
        XCTAssertEqual(record.productIdentifier, productIdentifier)
        XCTAssertEqual(record.expiryDate, expiryDate)
    }
}
