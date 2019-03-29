import XCTest
import Foundation
import StoreKit
@testable import MerchantKit

class ConstructedReceiptTests : XCTestCase {
    private let metadata = ReceiptMetadata(originalApplicationVersion: "1.0")
    
    func testDefaultDescription() {
        let entry1 = ReceiptEntry(productIdentifier: "testProduct1", expiryDate: nil)

        let receipt = ConstructedReceipt(from: [entry1], metadata: self.metadata)
        
        XCTAssertEqual(receipt.description, "[ConstructedReceipt productIdentifiers: [\"testProduct1\"]]")
    }
    
    func testDefaultDebugDescription() {
        let entry1 = ReceiptEntry(productIdentifier: "testProduct1", expiryDate: nil)
        
        let entry2: ReceiptEntry = {
            var components = DateComponents()
            components.day = 1
            components.month = 1
            components.year = 2000
            
            let expiryDate = Calendar(identifier: .gregorian).date(from: components)
            
            return ReceiptEntry(productIdentifier: "testProduct2", expiryDate: expiryDate)
        }()
        
        let entry3: ReceiptEntry = {
            var components = DateComponents()
            components.day = 2
            components.month = 1
            components.year = 2000
            
            let expiryDate = Calendar(identifier: .gregorian).date(from: components)
            
            return ReceiptEntry(productIdentifier: "testProduct2", expiryDate: expiryDate)
        }()
        
        let receipt = ConstructedReceipt(from: [entry1, entry2, entry3], metadata: self.metadata)
        let result = "ConstructedReceipt\n\n\t- testProduct1 (1 entries)\n\t\t- [ReceiptEntry productIdentifier: testProduct1, expiryDate: nil]\n\n\t- testProduct2 (2 entries)\n\t\t- [ReceiptEntry productIdentifier: testProduct2, expiryDate: 2000-01-01 00:00:00 +0000]\n\t\t- [ReceiptEntry productIdentifier: testProduct2, expiryDate: 2000-01-02 00:00:00 +0000]"

        XCTAssertEqual(receipt.debugDescription, result)
    }
    
    func testWithNoEntries() {
        let receipt = ConstructedReceipt(from: [], metadata: self.metadata)
        
        XCTAssertTrue(receipt.productIdentifiers.isEmpty)
        XCTAssertTrue(receipt.entries(forProductIdentifier: "").isEmpty)
    }
}
