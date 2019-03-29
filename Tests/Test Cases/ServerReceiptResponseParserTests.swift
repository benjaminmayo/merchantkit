import XCTest
import Foundation 
@testable import MerchantKit

class ServerReceiptResponseParserTests : XCTestCase {
    private var dataForTestSubscriptionResponse: Data? {
        guard let data = self.dataForSampleResource(withName: "testSubscriptionReceiptResponse", extension: "json") else {
            XCTFail("sample resource unavailable")
            
            return nil 
        }
        
        return data
    }
    
    private let testProductIdentifier = "testsubscription"
    
    func testParseValidDataSuccessful() {
        guard let receiptData = self.dataForTestSubscriptionResponse else { return }

        let parser = ServerReceiptVerificationResponseParser()
        
        XCTAssertNoThrow(try {
            let response = try parser.response(from: receiptData)
            _ = try parser.receipt(from: response)
        }())
    }
    
    func testReceiptContainsOneProduct() {
        guard let receiptData = self.dataForTestSubscriptionResponse else { return }
        
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
        guard let receiptData = self.dataForTestSubscriptionResponse else { return }
        
        let parser = ServerReceiptVerificationResponseParser()
        
        XCTAssertNoThrow(try {
            let response = try parser.response(from: receiptData)
            let receipt = try parser.receipt(from: response)
            
            let entries = receipt.entries(forProductIdentifier: self.testProductIdentifier)
            XCTAssertTrue(!entries.isEmpty)
        }())
    }
    
    func testReceiptContainsEntriesWithMatchingProductIdentifier() {
        guard let receiptData = self.dataForTestSubscriptionResponse else { return }
        
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
