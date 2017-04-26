/// A `Result` type encapsulating success and failure states.
public enum Result<Value> {
    case succeeded(Value)
    case failed(Error)
}
