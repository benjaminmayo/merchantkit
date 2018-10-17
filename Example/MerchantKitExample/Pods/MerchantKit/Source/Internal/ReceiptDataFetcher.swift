import Foundation

internal protocol ReceiptDataFetcher : AnyObject {
    init(policy: ReceiptFetchPolicy)
    
    func enqueueCompletion(_ completion: @escaping (Result<Data>) -> Void)
    func start()
    func cancel()
}

internal enum ReceiptFetchPolicy { // Ideally, would be `ReceiptDataFetcher.FetchPolicy`
    case alwaysRefresh
    case fetchElseRefresh
    case onlyFetch
}
