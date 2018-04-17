extension ASN1 {
    enum BufferValue : CustomStringConvertible {
        case null
        case boolean(Bool)
        case integer(Int)
        case string(String)
        case data(Data)
        case date(String)
        case objectIdentifier(ObjectIdentifier)
        
        var description: String {
            switch self {
                case .null:
                    return "null"
                case .boolean(let boolean):
                    return "\(boolean)"
                case .integer(let integer):
                    return "\(integer)"
                case .string(let string):
                    return string
                case .data(let data):
                    return "\(data)"
                case .date(let dateString):
                    return dateString
                case .objectIdentifier(let identifier):
                    return identifier.stringValue ?? "ASN1.ObjectIdentifier"
            }
        }
    }
}

