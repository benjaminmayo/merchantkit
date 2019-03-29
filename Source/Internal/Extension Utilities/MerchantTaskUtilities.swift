extension MerchantTask {
    internal func assertIfStartedBefore(file: StaticString = #file, line: UInt = #line) {
        if self.isStarted {
            MerchantKitFatalError.raise("This task has already started, and cannot be started again. It is an application logic error to start a `MerchantTask` repeatedly.", file: file, line: line)
        }
    }
}
