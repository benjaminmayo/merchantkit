internal protocol MerchantTask : class {

}

public typealias TaskCompletion<Value> = (Result<Value>) -> Void
