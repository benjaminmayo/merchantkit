public enum TaskResult<Value> {
    case succeeded(Value)
    case failed(Error)
}
