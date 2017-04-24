public enum Result<Value> {
    case succeeded(Value)
    case failed(Error)
}
