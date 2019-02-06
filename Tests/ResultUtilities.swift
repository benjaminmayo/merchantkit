extension Result where Failure == Error {
    internal func attemptMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Error> {
        switch self {
            case .success(let value):
                return Result<NewSuccess, Error> { try transform(value) }
            case .failure(let error):
                return .failure(error)
        }
    }
}
