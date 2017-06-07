/// TODO: Make this work.

internal final class LocalReceiptValidator {
    public typealias Completion = (Result<Receipt>) -> Void
    public let receiptData: Data
    
    public var onCompletion: Completion?
    
    public init(receiptData: Data) {
        self.receiptData = receiptData
    }
    
    public func start() {
        fatalError()
    }
}
