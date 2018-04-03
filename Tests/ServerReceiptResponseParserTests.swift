import XCTest
@testable import MerchantKit

class ServerReceiptResponseParserTests: XCTestCase {
    private func dataForResource(withName name: String, extension: String) -> Data {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: name, withExtension: `extension`)!
        
        return try! Data(contentsOf: url)
    }
    
    private var testSubscriptionResponseData: Data {
        return self.dataForResource(withName: "testSubscriptionReceiptResponse", extension: "json")
    }
    
    private let testProductIdentifier = "testsubscription"
    
    func testParseValidDataSuccessful() {
        let receiptData = self.testSubscriptionResponseData

        let parser = ServerReceiptVerificationResponseParser()
        
        XCTAssertNoThrow(try {
            let response = try parser.response(from: receiptData)
            _ = try parser.receipt(from: response)
        }())
    }
    
    func testReceiptContainsOneProduct() {
        let receiptData = self.testSubscriptionResponseData
        
        let parser = ServerReceiptVerificationResponseParser()
        
        XCTAssertNoThrow(try {
            let response = try parser.response(from: receiptData)
            let receipt = try parser.receipt(from: response)
            
            // receipt contains product identifier
            let first = receipt.productIdentifiers.first
            XCTAssertNotNil(first)
            
            // receipt only contains one productIdentifier
            XCTAssertEqual(receipt.productIdentifiers.count, 1)
            
            // receipt contains specific productIdentifier
            XCTAssertEqual(first!, self.testProductIdentifier)
        }())
    }
    
    func testReceiptContainsAtLeastOneEntry() {
        let receiptData = self.testSubscriptionResponseData
        
        let parser = ServerReceiptVerificationResponseParser()
        
        XCTAssertNoThrow(try {
            let response = try parser.response(from: receiptData)
            let receipt = try parser.receipt(from: response)
            
            let entries = receipt.entries(forProductIdentifier: self.testProductIdentifier)
            XCTAssertTrue(!entries.isEmpty)
        }())
    }
    
    func testReceiptContainsEntriesWithMatchingProductIdentifier() {
        let receiptData = self.testSubscriptionResponseData
        
        let parser = ServerReceiptVerificationResponseParser()
        
        XCTAssertNoThrow(try {
            let response = try parser.response(from: receiptData)
            let receipt = try parser.receipt(from: response)
            
            let entries = receipt.entries(forProductIdentifier: self.testProductIdentifier)
            XCTAssertTrue(!entries.isEmpty)
            
            let entriesWithDifferentProductIdentifier = entries.filter { $0.productIdentifier != self.testProductIdentifier }
            XCTAssertTrue(entriesWithDifferentProductIdentifier.isEmpty)
        }())
    }
}
