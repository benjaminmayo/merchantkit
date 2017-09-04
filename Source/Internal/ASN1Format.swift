internal enum ASN1Format {
    enum ParseError : Swift.Error {
        case malformed
        case invalidLength
    }
    
    struct RawAttribute {
        let type: Int
        let version: Int
        let data: Data
    }
    
    enum BufferKind: UInt8 {
        case integer = 0x02
        case octetString = 0x04
        case utf8String = 0x0c
        case ia5String = 0x16
        case sequence = 0x30
        case set = 0x31
    }
    
    typealias ParseResult<T> = (value: T, after: Data.Index)
    
    static func parseRawAttribute(startingAt index: Data.Index, in data: Data) throws -> ParseResult<RawAttribute> {
        let kind = data[index]
        
        guard kind == BufferKind.sequence.rawValue else { throw ParseError.malformed }
        
        var index = data.index(after: index)
        
        let (length, next) = try ASN1Format.parseLength(startingAt: index, in: data)
        let finalIndex = next.advanced(by: length)
        
        index = next
        
        struct ASN1ParseableComponent<T> {
            let kind: BufferKind
            let conversion: (_ index: Data.Index, _ byteCount: Int) throws -> ParseResult<T>
        }
        
        let integerComponent = ASN1ParseableComponent(kind: .integer, conversion: { index, byteCount in
            return try ASN1Format.parseInteger(startingAt: index, in: data, byteCount: byteCount)
        })
        
        let octetComponent = ASN1ParseableComponent(kind: .octetString, conversion: { index, byteCount in
            return try ASN1Format.parseOctetString(startingAt: index, in: data, byteCount: byteCount)
        })
        
        func processComponent<T>(_ component: ASN1ParseableComponent<T>) throws -> T {
            let kind = data[index]
            
            guard kind == component.kind.rawValue else { throw ParseError.malformed }
            index = data.index(after: index)
            
            let (byteCount, next) = try ASN1Format.parseLength(startingAt: index, in: data)
            index = next
            
            let (result, next2) = try component.conversion(index, byteCount)
            
            index = next2
            
            return result
        }
        
        let typeIdentifier = try processComponent(integerComponent)
        let version = try processComponent(integerComponent)
        let data = try processComponent(octetComponent)
        
        return (RawAttribute(type: typeIdentifier, version: version, data: data), index)
    }
    
    static func parseLength(startingAt index: Data.Index, in data: Data) throws -> ParseResult<Int> {
        let byte = data[index]
        
        if ((byte & 0x80) == 0x00) {
            let next = data.index(after: index)
            
            return (Int(byte), next)
        } else if ((byte & 0x7f) > 0x00) {
            let byteCount = Int(byte & 0x7f)
            let next = data.index(after: index)
            
            if next.advanced(by: byteCount) >= data.endIndex {
                throw ParseError.invalidLength
            }
            
            return try self.parseInteger(startingAt: next, in: data, byteCount: byteCount)
        } else {
            throw ParseError.malformed
        }
    }
    
    static func parseInteger(startingAt index: Data.Index, in data: Data, byteCount: Int) throws -> ParseResult<Int> {
        var result: UInt64 = 0
        
        let bytes = data[index..<data.index(index, offsetBy: byteCount)]
        
        for (index, byte) in bytes.enumerated() {
            result |= (UInt64(byte) << UInt64((byteCount - 1 - index) * 8))
        }
        
        return (Int(result), bytes.endIndex)
    }
    
    static func parseOctetString(startingAt index: Data.Index, in data: Data, byteCount: Int) throws -> ParseResult<Data> {
        let slice = data[index..<data.index(index, offsetBy: byteCount)]
        
        return (slice, slice.endIndex)
    }
}
