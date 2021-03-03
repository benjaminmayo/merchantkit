import Foundation

public final class KeychainPurchaseStorage : PurchaseStorage {
    private let serviceName: String
    private let accessGroup: String?
    
    var purchaseRecordCache = [String : PurchaseRecord]()
    
    public init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    private let storageKeyPrefix: String = "purchaseStorage"

    public func record(forProductIdentifier productIdentifier: String) -> PurchaseRecord? {
        let storageKey = self.storageKey(forProductIdentifier: productIdentifier)
        
        if let record = self.purchaseRecordCache[productIdentifier] {
            return record
        }
        
        do {
            let dict = try self.dictFromKeychain(forKey: storageKey)
            
            if let record = PurchaseRecord(from: dict) {
                self.purchaseRecordCache[productIdentifier] = record
                
                return record
            }
        } catch {
            
        }
        
        return nil
    }
    
    public func save(_ record: PurchaseRecord) -> PurchaseStorageUpdateResult {
        let storageKey = self.storageKey(forProductIdentifier: record.productIdentifier)

        let result = self.saveToKeychain(record.dictionaryRepresentation, forKey: storageKey)
        
        if result == .didChangeRecords {
            self.purchaseRecordCache.removeValue(forKey: record.productIdentifier)
        }
        
        return result
    }
    
    public func removeRecord(forProductIdentifier productIdentifier: String) -> PurchaseStorageUpdateResult {
        let storageKey = self.storageKey(forProductIdentifier: productIdentifier)
        self.purchaseRecordCache.removeValue(forKey: productIdentifier)

        do {
            try self.removeDictFromKeychain(forKey: storageKey)
            
            return .didChangeRecords
        } catch {
            return .noChanges
        }
    }
    
    private func storageKey(forProductIdentifier productIdentifier: String) -> String {
        return self.storageKeyPrefix + "." + productIdentifier
    }
    
    private func saveToKeychain(_ dict: [String : AnyHashable], forKey key: String) -> PurchaseStorageUpdateResult {
        guard let encodedData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0) else { return .noChanges }
    
        do {
            let existingDict = try self.dictFromKeychain(forKey: key)
            
            if dict != existingDict {
                // update keychain
                
                let updateQuery = self.keychainQuery(forKey: key)
                
                var updatingAttributes = [String : Any]()
                updatingAttributes[kSecValueData as String] = encodedData
                
                let status = SecItemUpdate(updateQuery as CFDictionary, updatingAttributes as CFDictionary)
                
                guard status == noErr else { throw KeychainError.other(status) }
                
                return .didChangeRecords
            }
        } catch KeychainError.noneFound {
            // add to keychain
            
            var newItemQuery = self.keychainQuery(forKey: key)
            newItemQuery[kSecValueData as String] = encodedData
            
            let status = SecItemAdd(newItemQuery as CFDictionary, nil)
            
            if status == noErr {
                return .didChangeRecords
            }
        } catch {
            
        }
        
        return .noChanges
    }
    
    private func resultFromKeychain(forQuery query: [String : Any]) -> (OSStatus, AnyObject?) {
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result, {
            SecItemCopyMatching(query as CFDictionary, $0)
        })
        
        return (status, result)
    }
    
    private func keychainFindQuery(forKey key: String) -> [String : Any] {
        var query = self.keychainQuery(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        return query
    }
    
    private func dictFromKeychain(forKey key: String) throws -> [String : AnyHashable] {
        let query = self.keychainFindQuery(forKey: key)
        
        let (status, result) = self.resultFromKeychain(forQuery: query)
        
        guard status != errSecItemNotFound else { throw KeychainError.noneFound }
        guard status == noErr else { throw KeychainError.other(status) }
        
        guard
            let item = result as? [String : Any],
            let data = item[kSecValueData as String] as? Data
        else { throw KeychainError.unexpectedData }
        
        guard let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil), let dict = propertyList as? [String : AnyHashable] else { throw KeychainError.unexpectedData }
        
        return dict
    }
    
    private func removeDictFromKeychain(forKey key: String) throws {
        let query = self.keychainQuery(forKey: key)
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecItemNotFound {
            throw KeychainError.noneFound
        }
        
        guard status == noErr else { throw KeychainError.other(status) }
    }
    
    private func keychainQuery(forKey key: String) -> [String : Any] {
        var query = [String : Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = self.serviceName
        
        query[kSecAttrAccount as String] = key
        
        if let accessGroup = self.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
        
    private enum KeychainError : Swift.Error {
        case noneFound
        case unexpectedData
        case other(OSStatus)
    }
}
