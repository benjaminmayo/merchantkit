/// `StoreParameters` control certain behaviour of transactions in the underlying `StoreKit` API. Refer to the StoreKit documentation for a definitive explanation of these properties.
public struct StoreParameters {
    /// The `applicationUsername` is used by the iTunes servers to detect spam and misuse. It is recommended to set this as a one-way hash of the current account name, if available. For instance, multiple purchases from the same `applicationUsername` across many devices simultaneously will be flagged as suspicious. Defaults to empty string (unused).
    public var applicationUsername: String = ""
}
