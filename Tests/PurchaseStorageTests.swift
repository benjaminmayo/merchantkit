import XCTest
import Foundation
@testable import MerchantKit

class PurchaseStorageTests : XCTestCase {
    private var testablePurchaseStorageTypes: [PurchaseStorage] {
        let ephemeralPurchaseStorage = EphemeralPurchaseStorage()
        
        UserDefaults.standard.removePersistentDomain(forName: "PurchaseStorageTests")
        let defaults = UserDefaults(suiteName: "PurchaseStorageTests")!
        
        let userDefaultsPurchaseStorage = UserDefaultsPurchaseStorage(defaults: defaults)
        
        return [ephemeralPurchaseStorage, userDefaultsPurchaseStorage]
    }
    
    func testSaveRecord() {
        for storage in self.testablePurchaseStorageTypes {
            let testRecord = self.testRecord
            
            let result = storage.save(testRecord)
            
            XCTAssertEqual(result, PurchaseStorageUpdateResult.didChangeRecords)
            let record = storage.record(forProductIdentifier: testRecord.productIdentifier)
            
            XCTAssertNotNil(record)
            XCTAssertEqual(record, testRecord)
        }
    }
    
    func testDeleteRecord() {
        for storage in self.testablePurchaseStorageTypes {
            let testRecord = self.testRecord
            
            let saveResult = storage.save(testRecord)
            
            XCTAssertEqual(saveResult, PurchaseStorageUpdateResult.didChangeRecords)
            let record = storage.record(forProductIdentifier: testRecord.productIdentifier)
            
            XCTAssertNotNil(record)
            XCTAssertEqual(record, testRecord)
            
            let deletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(deletionResult, PurchaseStorageUpdateResult.didChangeRecords)
            
            XCTAssertNil(storage.record(forProductIdentifier: testRecord.productIdentifier))
        }
    }
    
    func testSaveSameRecord() {
        for storage in self.testablePurchaseStorageTypes {
            let testRecord = self.testRecord
            
            let result = storage.save(testRecord)
            XCTAssertEqual(result, PurchaseStorageUpdateResult.didChangeRecords)
            
            let repeatedResult = storage.save(testRecord)
            XCTAssertEqual(repeatedResult, PurchaseStorageUpdateResult.noChanges)
        }
    }
    
    func testRemoveSameRecord() {
        for storage in self.testablePurchaseStorageTypes {
            let testRecord = self.testRecord
        
            _ = storage.save(testRecord)

            let deletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(deletionResult, PurchaseStorageUpdateResult.didChangeRecords)
        
            let repeatedDeletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(repeatedDeletionResult, PurchaseStorageUpdateResult.noChanges)
        }
    }
    
    private var testRecord: PurchaseRecord {
        return PurchaseRecord(productIdentifier: "testSubscriptionProduct", expiryDate: Date())
    }
}
