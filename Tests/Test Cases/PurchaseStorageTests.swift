import XCTest
import Foundation
@testable import MerchantKit

class PurchaseStorageTests : XCTestCase {
    private var testablePurchaseStorages = [PurchaseStorage]()
    
    override func setUp() {
        let ephemeralPurchaseStorage = EphemeralPurchaseStorage()
        let userDefaultsPurchaseStorage = UserDefaultsPurchaseStorage(defaults: .standard)
        let keychainPurchaseStorage = KeychainPurchaseStorage(serviceName: "PurchaseStorageTests")
        
        self.testablePurchaseStorages = [ephemeralPurchaseStorage, userDefaultsPurchaseStorage, keychainPurchaseStorage]
        
        for storage in self.testablePurchaseStorages {
            _ = storage.removeRecord(forProductIdentifier: self.testRecord.productIdentifier)
        }
    }
    
    func testSaveRecord() {
        for storage in self.testablePurchaseStorages {
            for testRecord in [self.testRecord, self.testRecordWithDifferentExpiryDate] {
                let result = storage.save(testRecord)
                
                XCTAssertEqual(result, PurchaseStorageUpdateResult.didChangeRecords)
                let record = storage.record(forProductIdentifier: testRecord.productIdentifier)
                
                XCTAssertNotNil(record)
                XCTAssertEqual(record, testRecord)
            }
        }
    }
    
    func testDeleteRecord() {
        for storage in self.testablePurchaseStorages {
            let testRecord = self.testRecord
            
            let saveResult = storage.save(testRecord)
            
            XCTAssertEqual(saveResult, PurchaseStorageUpdateResult.didChangeRecords)
            let record = storage.record(forProductIdentifier: testRecord.productIdentifier)
            
            XCTAssertNotNil(record)
            XCTAssertEqual(record, testRecord)
            
            let recordWithRepeatedRequestForSameRecord = storage.record(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(recordWithRepeatedRequestForSameRecord, testRecord)
            
            let deletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(deletionResult, PurchaseStorageUpdateResult.didChangeRecords)
            
            XCTAssertNil(storage.record(forProductIdentifier: testRecord.productIdentifier), "Deleted record still exists for \(storage).")
        }
    }
    
    func testSaveSameRecord() {
        for storage in self.testablePurchaseStorages {
            let testRecord = self.testRecord
            
            let result = storage.save(testRecord)
            XCTAssertEqual(result, PurchaseStorageUpdateResult.didChangeRecords)
            
            let repeatedResult = storage.save(testRecord)
            XCTAssertEqual(repeatedResult, PurchaseStorageUpdateResult.noChanges, "Saving the same record twice should report `noChanges` for \(storage).")
        }
    }
    
    func testRemoveSameRecord() {
        for storage in self.testablePurchaseStorages {
            let testRecord = self.testRecord
        
            _ = storage.save(testRecord)

            let deletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(deletionResult, PurchaseStorageUpdateResult.didChangeRecords)
        
            let repeatedDeletionResult = storage.removeRecord(forProductIdentifier: testRecord.productIdentifier)
            XCTAssertEqual(repeatedDeletionResult, PurchaseStorageUpdateResult.noChanges, "Deleting the same record twice should report `noChanges` for \(storage).")
        }
    }
    
    private var testRecord: PurchaseRecord {
        return PurchaseRecord(productIdentifier: "testSubscriptionProduct", expiryDate: Date())
    }
    
    private var testRecordWithDifferentExpiryDate: PurchaseRecord {
        return PurchaseRecord(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: 60 * 60 * 24 * 7))
    }
}
