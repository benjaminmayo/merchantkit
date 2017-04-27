/// A wrapper collection that provides a simple way to make buckets of objects grouped under a given unique key.
internal struct Buckets<Key : Hashable, Value> {
    /// `keys` enumerates the keys for all buckets which have at least one element inside.
    private(set) var keys = Set<Key>()
    
    fileprivate typealias Storage = [Key : [Value]]
    private var storage = Storage()
    
    init() {
        
    }
    
    // Returns true if there are no buckets with at least one element.
    var isEmpty: Bool {
        return self.keys.isEmpty
    }
    
    subscript (key: Key) -> [Value] {
        get {
            return self.storage[key] ?? []
        }
        
        set {
            if newValue.isEmpty {
                self.keys.remove(key)
                
                self.storage.removeValue(forKey: key)
            } else {
                self.keys.insert(key)
                
                self.storage[key] = newValue
            }
        }
    }
    
    mutating func removeAll() {
        self.keys.removeAll()
        self.storage.removeAll()
    }
    
    mutating func removeAll(for key: Key) {
        self.keys.remove(key)
        self.storage.removeValue(forKey: key)
    }
}
