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
        
        if let dict = try? self.dictFromKeychain(forKey: storageKey) {
            if let record = PurchaseRecord(from: dict) {
                self.purchaseRecordCache[productIdentifier] = record
                
                return record
            }
        }
        
        return nil
    }
    
    public func save(_ record: PurchaseRecord) -> PurchaseStorageUpdateResult {
        let storageKey = self.storageKey(forProductIdentifier: record.productIdentifier)

        do {
            try self.saveToKeychain(record.dictionaryRepresentation, forKey: storageKey)
            self.purchaseRecordCache.removeValue(forKey: record.productIdentifier)

            return .didChangeRecords
        } catch {            
            return .noChanges
        }
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
    
    private func saveToKeychain(_ dict: [String : Any], forKey key: String) throws {
        let encodedData = try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
    
        let (status, _) = self.resultFromKeychain(forQuery: self.keychainFindQuery(forKey: key))
        
        if status == errSecItemNotFound {
            // add to keychain
            
            var newItemQuery = self.keychainQuery(forKey: key)
            newItemQuery[kSecValueData as String] = encodedData
            
            let status = SecItemAdd(newItemQuery as CFDictionary, nil)
            
            guard status == noErr else { throw KeychainError.other(status) }
        } else {
            // update keychain
            
            let updateQuery = self.keychainQuery(forKey: key)
            
            var updatingAttributes = [String : Any]()
            updatingAttributes[kSecValueData as String] = encodedData
            
            let status = SecItemUpdate(updateQuery as CFDictionary, updatingAttributes as CFDictionary)
            
            guard status == noErr else { throw KeychainError.other(status) }
        }
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
    
    private func dictFromKeychain(forKey key: String) throws -> [String : Any] {
        let query = self.keychainFindQuery(forKey: key)
        
        let (status, result) = self.resultFromKeychain(forQuery: query)
        
        guard status != errSecItemNotFound else { throw KeychainError.noneFound }
        guard status == noErr else { throw KeychainError.other(status) }
        
        guard
            let item = result as? [String : Any],
            let data = item[kSecValueData as String] as? Data
        else { throw KeychainError.unexpectedData }
        
        guard let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil), let dict = propertyList as? [String : Any] else { throw KeychainError.unexpectedData }
        
        return dict
    }
    
    private func removeDictFromKeychain(forKey key: String) throws {
        let query = self.keychainQuery(forKey: key)
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.other(status) }
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
