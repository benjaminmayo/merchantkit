public enum StoreIntentResponse {
    case automaticallyCommit
    case `defer`
    
    public static var `default`: StoreIntentResponse {
        return .automaticallyCommit
    }
}
