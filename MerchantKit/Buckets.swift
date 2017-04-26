internal struct Buckets<Key : Hashable, Value> {
    fileprivate typealias Storage = [Key : [Value]]
    private var storage = Storage()
    public private(set) var keys = Set<Key>()
    
    init() {
        
    }
    
    subscript (key: Key) -> [Value] {
        get {
            return self.storage[key] ?? []
        }
        
        set {
            self.storage[key] = newValue
            
            if newValue.isEmpty {
                self.keys.remove(key)
            } else {
                self.keys.insert(key)
            }
        }
    }
}
