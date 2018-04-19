import XCTest
import Foundation
@testable import MerchantKit

class PKCS7ReceiptDataContainerTests : XCTestCase {
    func testEmptyData() {
        let container = PKCS7ReceiptDataContainer(receiptData: Data())
        
        XCTAssertThrowsError(try container.content())
    }
    
    func testValidData() {
        let url = self.urlForSampleResource(withName: "testSampleReceiptTwoNonconsumblesPurchased", extension: "data")
        
        guard let data = try? Data(contentsOf: url) else {
            XCTFail("no data at \(url)")
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
