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
    
    func testExtractContentEarlyDoesNotBubbleError() {
        let contentBytes: [UInt8] = [8, 8, 8, 8]
        
        var data = Data()
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.objectIdentifier), valueKind: .primitive).byte)
        data.append(9)
        data.append(contentsOf: [42, 134, 72, 134, 247, 13, 1, 7, 1])
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.octetString), valueKind: .primitive).byte)
        data.append(UInt8(contentBytes.count))
        data.append(contentsOf: contentBytes)
        data.append(8)
        data.append(contentsOf: [UInt8](repeating: 0, count: 10))
        
        do {
            let container = PKCS7ReceiptDataContainer(receiptData: data)
        
            let foundContent = try container.content()
            let foundContentBytes = foundContent.map { $0 }
            
            XCTAssertEqual(contentBytes, foundContentBytes, "The content was expected to equal \(contentBytes) when \(foundContentBytes) was expected.")
        } catch let error {
            XCTFail("The container failed with error \(error) when it was expected to succeed.")
        }
    }
}
