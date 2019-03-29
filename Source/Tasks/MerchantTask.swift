/// Merchant Tasks are vended by a `Merchant` instance. Use the callbacks associated with each `MerchantTask` to be notified of task progress.
/// Tasks must be started using the `start` method, typically immediately after configuration. Some tasks may be cancellable.
public protocol MerchantTask : AnyObject {
    var isStarted: Bool { get }
    
    /// Start the task, after previously configuring how it behaves.
    func start()
}

// The prototype completion handler for a `MerchantTask`. This may be called from any thread. See individual task interfaces for usage details.
public typealias MerchantTaskCompletion<Value> = (Result<Value, Error>) -> Void
