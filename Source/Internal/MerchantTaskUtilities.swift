extension MerchantTask {
    internal func assertIfStartedBefore(file: StaticString = #file, line: UInt = #line) {
        if self.isStarted {
            MerchantKitFatalError.raise("This task can only be started once.", file: file, line: line)
        }
    }
}
