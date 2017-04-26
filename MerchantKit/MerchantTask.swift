/// Merchant Tasks are vended by a `Merchant` instance. Use the callbacks associated with each `MerchantTask` to be notified of task progress.
/// Tasks must be started using the `start` method. Some tasks may be cancellable.
internal protocol MerchantTask : class {
    /// Start the task, after previously configuring how it behaves.
    func start()
}

public typealias TaskCompletion<Value> = (Result<Value>) -> Void
