internal protocol AvailablePurchasesFetcher : AnyObject {
    init(forProducts: Set<Product>)
    
    func enqueueCompletion(_ completion: @escaping (Result<PurchaseSet, Error>) -> Void)
    func start()
    func cancel()
}
