import XCTest
import Foundation
@testable import MerchantKit

class EphemeralPurchaseStorageTests : XCTestCase {
    func testSaveRecord() {
        let testRecord = self.testRecord
        
        let storage = EphemeralPurchaseStorage()
        let result = storage.save(testRecord)
        
        XCTAssertEqual(result, PurchaseStorageUpdateResult.didChangeRecords)
        let record = storage.record(forProductIdentifier: testRecord.productIdentifier)
        
        XCTAssertNotNil(record)
        XCTAssertEqual(record, testRecord)
    }
    
    func testDeleteRecord() {
        let testRecord = self.testRecord
        
        let storage = EphemeralPurchaseStorage()
        let saveResult = storage.save(testRecord)
        
        XCTAssertEqual(saveResult, PurchaseStorageUpdateResult.didChangeRecords)
        let record = storage.record(forProductIdentifier: testRecord.productIdentifier)
        
        XCTAssertNotNil(record)
        XCTAssertEqual(record, testRecord)
        
        let deletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
        XCTAssertEqual(deletionResult, PurchaseStorageUpdateResult.didChangeRecords)
        
        XCTAssertNil(storage.record(forProductIdentifier: testRecord.productIdentifier))
    }
    
    func testSaveSameRecord() {
        let testRecord = self.testRecord
        
        let storage = EphemeralPurchaseStorage()
        
        let result = storage.save(testRecord)
        XCTAssertEqual(result, PurchaseStorageUpdateResult.didChangeRecords)
        
        let repeatedResult = storage.save(testRecord)
        XCTAssertEqual(repeatedResult, PurchaseStorageUpdateResult.noChanges)
    }
    
    func testRemoveSameRecord() {
        let testRecord = self.testRecord
        
        let storage = EphemeralPurchaseStorage()
        _ = storage.save(testRecord)

        let deletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
        XCTAssertEqual(deletionResult, PurchaseStorageUpdateResult.didChangeRecords)
        
        let repeatedDeletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
        XCTAssertEqual(repeatedDeletionResult, PurchaseStorageUpdateResult.noChanges)
    }
    
    private var testRecord: PurchaseRecord {
        return PurchaseRecord(productIdentifier: "testSubscriptionProduct", expiryDate: Date())
    }
}
