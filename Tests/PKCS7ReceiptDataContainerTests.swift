import XCTest
import Foundation
@testable import MerchantKit

class PKCS7ReceiptDataContainerTests : XCTestCase {
    func testEmptyData() {
        let container = PKCS7ReceiptDataContainer(receiptData: Data())
        
        XCTAssertThrowsError(try container.content())
    }
    
    func testValidData() {
        guard let data = self.dataForSampleResource(withName: "testSampleReceiptTwoNonConsumablesPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            return
        }
        
        let container = PKCS7ReceiptDataContainer(receiptData: data)
        
        var extractedData: Data!
        XCTAssertNoThrow(extractedData = try container.content())
        
        var repeatedlyExtractedData: Data!
        XCTAssertNoThrow(repeatedlyExtractedData = try container.content())
        
        XCTAssertEqual(extractedData, repeatedlyExtractedData)
    }
}
