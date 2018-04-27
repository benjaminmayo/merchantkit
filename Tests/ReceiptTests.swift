import XCTest
import Foundation
import StoreKit
@testable import MerchantKit

class ReceiptTests : XCTestCase {
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
        
        let receipt = ConstructedReceipt(from: [entry1, entry2])
        let result = "ConstructedReceipt\n\n\t- testProduct1 (1 entries)\n\t\t- [ReceiptEntry productIdentifier: testProduct1, expiryDate: nil]\n\n\t- testProduct2 (1 entries)\n\t\t- [ReceiptEntry productIdentifier: testProduct2, expiryDate: 2000-01-01 00:00:00 +0000]"

        XCTAssertEqual(receipt.debugDescription, result)
    }
}
