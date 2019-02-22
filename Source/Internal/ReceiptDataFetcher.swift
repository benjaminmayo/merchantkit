import Foundation

internal protocol ReceiptDataFetcher : AnyObject {
    func enqueueCompletion(_ completion: @escaping (Result<Data, Error>) -> Void)
    func start()
    func cancel()
}

internal enum ReceiptFetchPolicy { // Ideally, would be `ReceiptDataFetcher.FetchPolicy`
    case alwaysRefresh
    case fetchElseRefresh
    case onlyFetch
}

internal enum ReceiptFetchError : Error {
    case receiptUnavailableWithoutRefresh
}
