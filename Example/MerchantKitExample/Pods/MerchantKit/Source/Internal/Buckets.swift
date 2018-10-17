/// A wrapper collection that provides a simple way to make buckets of objects grouped under a given unique key.
internal struct Buckets<Key : Hashable, Value> {
    /// `keys` enumerates the keys for all buckets which have at least one element inside.
//    private(set) var keys = Set<Key>()
    
    private typealias Storage = [Key : [Value]]
    private var storage = Storage()
    
    init() {
        
    }
    
    var keys: Set<Key> {
        return Set(self.storage.keys)
    }
    
    // Returns true if there are no buckets with at least one element.
    var isEmpty: Bool {
        return self.storage.isEmpty
    }
    
    subscript (key: Key) -> [Value] {
        get {
            return self.storage[key] ?? []
        }
        
        set {
            if newValue.isEmpty {
                self.storage.removeValue(forKey: key)
            } else {
                self.storage[key] = newValue
            }
        }
    }
    
    mutating func removeAll() {
        self.storage.removeAll()
    }
    
    mutating func removeAll(for key: Key) {
        self.storage.removeValue(forKey: key)
    }
}
