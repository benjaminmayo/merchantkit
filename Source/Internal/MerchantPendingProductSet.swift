extension Merchant {
    internal struct PendingProductSet {
        private var products = [Event : Set<Product>]()
        
        internal init() {
            
        }
        
        internal subscript (event: Event) -> Set<Product> {
            get {
                return self.products[event, default: []]
            }
            
            set {
                self.products[event, default: []] = newValue
            }
        }
        
        internal enum Event {
            case purchased
            case restored
        }
    }
}
