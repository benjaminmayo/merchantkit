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
    
    func testReceiptDataWithMalformedContainer() {
        let data = Data([0b11000001, 1, 1])
        
        let container = PKCS7ReceiptDataContainer(receiptData: data)
        XCTAssertThrowsError(_ = try container.content(), "", { error in
            switch error {
                case PKCS7ReceiptDataContainer.Error.malformedContainer:
                    break
                case let error:
                    XCTFail("The `PKCS7ReceiptDataContainer.content()` failed with error \(error) but error \(PKCS7ReceiptDataContainer.Error.malformedContainer) was expected.")
            }
        })
    }
}
