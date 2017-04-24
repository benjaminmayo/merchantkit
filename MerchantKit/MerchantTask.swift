internal protocol MerchantTask : class {
    init(for merchant: Merchant)
}

public typealias TaskCompletion<Value> = (Result<Value>) -> Void
