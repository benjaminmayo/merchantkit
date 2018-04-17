
internal struct ASN1ReceiptAttributeSet<AttributeType> : Sequence where AttributeType : RawRepresentable, AttributeType.RawValue == Int {
    private let iterator: Iterator
    
    init(in data: Data, of type: AttributeType.Type) throws {
        self.iterator = try Iterator(data: data)
    }
    
    func makeIterator() -> Iterator {
        return self.iterator
    }
}

extension ASN1ReceiptAttributeSet {
    struct Attribute {
        let type: AttributeType
        let version: Int
        
        private let rawValue: Data
        
        fileprivate init(type: AttributeType, version: Int, rawValue: Data) {
            self.type = type
            self.version = version
            self.rawValue = rawValue
        }
        
        var byteValue: Data {
            return self.rawValue
        }
        
        var stringValue: String? {
            guard let (kind, byteOffset, byteCount) = self.typedBuffer else { return nil }
            
            let encoding: String.Encoding
            
            switch kind {
                case .utf8String:
                    encoding = .utf8
                case .ia5String:
                    encoding = .ascii
                default:
                    return nil
            }
            
            let bytes = self.rawValue[byteOffset..<self.rawValue.index(byteOffset, offsetBy: byteCount)]
            
            return String(bytes: bytes, encoding: encoding)
        }
        
        var integerValue: Int? {
            guard let (kind, byteOffset, byteCount) = self.typedBuffer, kind == .integer else { return nil }
            
            return try? ASN1Format.parseInteger(startingAt: byteOffset, in: self.rawValue, byteCount: byteCount).value
        }
        
        var dateValue: Date? {
            return self.stringValue.flatMap {
                return $0.isEmpty ? nil : Date(fromISO8601: $0)
            }
        }
    }
}

extension ASN1ReceiptAttributeSet : CustomStringConvertible {
    public var description: String {
        var description = "ASN1ReceiptAttributeSet\n"
        
        for attribute in self {
            description += "\(attribute)\n"
        }
        
        return description
    }
}

extension ASN1ReceiptAttributeSet {
    internal struct Iterator : Sequence, IteratorProtocol {
        private let data: Data
        var cursor: Data.Index
        var endIndex: Data.Index
        
        init(data: Data) throws {
            self.data = data
            self.cursor = data.startIndex
            self.endIndex = data.endIndex
            
            guard self.cursor < self.endIndex else {
                throw ASN1Format.ParseError.invalidLength
            }
            
            let kind = self.data[self.cursor]
                        
            guard kind == ASN1Format.BufferKind.set.rawValue else {
                throw ASN1Format.ParseError.malformed
            }
            
            self.cursor = self.data.index(after: self.cursor)
            
            let (_, next) = try ASN1Format.parseLength(startingAt: self.cursor, in: self.data)
            
            self.cursor = next
        }
        
        mutating func next() -> Attribute? {
            while true {
                do {
                    let (rawAttribute, next) = try ASN1Format.parseRawAttribute(startingAt: self.cursor, in: self.data)
                    
                    self.cursor = next
                    
                    if let type = AttributeType(rawValue: rawAttribute.type) {
                        let attribute = Attribute(type: type, version: rawAttribute.version, rawValue: rawAttribute.data)
                        
                        return attribute
                    }
                } catch _ {
                    return nil
                }
            }
        }
    }
}

extension ASN1ReceiptAttributeSet.Attribute {
    private var typedBuffer: (kind: ASN1Format.BufferKind, byteOffset: Data.Index, byteCount: Int)? {
        guard let kindIdentifier = self.rawValue.first, let kind = ASN1Format.BufferKind(rawValue: kindIdentifier) else {
            return nil
        }
        
        guard let (byteCount, offset) = try? ASN1Format.parseLength(startingAt: self.rawValue.index(after: self.rawValue.startIndex), in: self.rawValue) else { return nil }
        
        return (kind, offset, byteCount)
    }
}
