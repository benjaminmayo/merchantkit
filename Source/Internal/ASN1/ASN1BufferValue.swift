import Foundation

extension ASN1 {
    enum BufferValue : Equatable, CustomStringConvertible {
        case null
        case boolean(Bool)
        case integer(Int)
        case string(String)
        case data(Data)
        case date(String)
        case objectIdentifier(ObjectIdentifier)
        
        var description: String {
            let formattedValue: String
            
            switch self {
                case .null:
                    formattedValue = "null"
                case .boolean(let boolean):
                    formattedValue = "\(boolean)"
                case .integer(let integer):
                    formattedValue = "\(integer)"
                case .string(let string):
                    formattedValue = "'\(string)'"
                case .data(let data):
                    formattedValue = "\(data)"
                case .date(let dateString):
                    formattedValue = "'\(dateString)'"
                case .objectIdentifier(let identifier):
                    formattedValue = "\(identifier)"
            }
            
            return self.defaultDescription(typeName: "ASN1.BufferValue", withProperties: ("value", formattedValue))
        }
    }
}

