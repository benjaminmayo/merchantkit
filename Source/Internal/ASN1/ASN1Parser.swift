import Foundation

protocol ASN1ParserDelegate : AnyObject {
    func asn1Parser(_ parser: ASN1.Parser, didParse token: ASN1.Parser.Token)
}

extension ASN1 {
    /// Parses any ASN1 data in an event-driven manner. Data is relayed as a stream of tokens to the delegate.
    /// The aim of the parser is to never fatally trap. All errors should be funneled through the API. This aim is not yet fully implemented.
    class Parser {
        weak var delegate: ASN1ParserDelegate?
        
        private let data: Data
        
        private var didAbort: Bool = false
        
        init(data: Data) {
            self.data = data
        }
        
        enum Token {
            case contextStart(type: UInt8)
            case contextEnd(type: UInt8)
            case containerStart(type: ASN1.BufferType)
            case containerEnd(type: ASN1.BufferType)
            case value(ASN1.BufferValue)
        }
        
        func parse() throws {
            defer {
                self.reset()
            }
            
            if self.data.isEmpty { throw Error.emptyData }
            
            var remainingData = self.data
            
            while !remainingData.isEmpty {
                remainingData = try self._parse(subdata: remainingData)
            }
        }
        
        // You can call this partway through parsing, but it is not guaranteed to stop token events to the delegate. The parse() method will bubble up an `Error.abort` at termination.
        func abortParsing() {
            self.didAbort = true
        }
        
        enum Error : Swift.Error {
            case emptyData
            case aborted
            case unknownASN1Type(UInt8)
            case usesLongFormNotSupported
            case malformedLengthForData
        }
    }
}

extension ASN1.Parser {
    internal struct PayloadDescriptor {
        internal let domain: Domain
        internal let tag: Tag
        internal let valueKind: ValueKind
        
        internal init(domain: Domain, tag: Tag, valueKind: ValueKind) {
            self.domain = domain
            self.tag = tag
            self.valueKind = valueKind
        }
        
        internal init(from byte: UInt8) {
            // Octet:   | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 |
            // Decoded: |Domain_|IsC|TagNumber__________|
            
            // Domain is first two bits, one of Domain values
            // isConstructed is 0 or 1 bit, 1 for true
            // Remaining bits is tag number, can be custom if domain is context specific
            
            let domainRawValue = byte >> 6
            
            let domain = Domain(rawValue: domainRawValue)!
            
            let isConstructed = ((byte >> 5) & 1) == 1
            let valueKind: ValueKind = isConstructed ? .constructed : .primitive
            
            let tagRawValue = byte & 0x1f

            let tag: Tag = ASN1.BufferType(rawValue: tagRawValue).map { .type($0) } ?? .custom(tagRawValue)
            
            self.init(domain: domain, tag: tag, valueKind: valueKind)
        }
        
        enum Domain : UInt8, Equatable {
            case universal = 0x0
            case application = 0x1
            case contextSpecific = 0x2
            case `private` = 0x3
        }
        
        enum ValueKind : Equatable {
            case primitive
            case constructed
        }
        
        enum Tag : Equatable {
            case custom(UInt8)
            case type(ASN1.BufferType)
            
            var type: ASN1.BufferType? {
                switch self {
                    case .type(let type): return type
                    default: return nil
                }
            }
            
            var rawType: UInt8 {
                switch self {
                    case .type(let type): return type.rawValue
                    case .custom(let type): return type
                }
            }
        }
        
        func withTag(_ tag: Tag) -> PayloadDescriptor {
            return PayloadDescriptor(domain: self.domain, tag: tag, valueKind: self.valueKind)
        }
    }
    
    private func reset() {
        self.didAbort = false
    }
    
    private func _parse(subdata: Data) throws -> Data {
        var shouldStopParsing = false
        var stopParsingError: Swift.Error!
        
        if self.didAbort {
            throw Error.aborted
        }

        var descriptor = PayloadDescriptor(from: subdata.first!)
        
        if descriptor.tag.type == ASN1.BufferType.usesLongForm {
            throw Error.usesLongFormNotSupported
        }
        
        let (length, subdata) = try ASN1.consumeLength(from: subdata[subdata.index(after: subdata.startIndex)...])
        
        guard let bufferEndIndex = subdata.index(subdata.startIndex, offsetBy: length, limitedBy: subdata.endIndex) else {
            throw Error.malformedLengthForData
        }
        
        let buffer = subdata[..<bufferEndIndex]
        
        if descriptor.domain == .contextSpecific {
            self.delegate?.asn1Parser(self, didParse: .contextStart(type: descriptor.tag.rawType))
            
            // parser did start context with tag
            
            if descriptor.valueKind == .primitive {
                descriptor = descriptor.withTag(.type(.octetString))
            }
        }
        
        if descriptor.valueKind == .constructed {
            // did start container with type
            if let type = descriptor.tag.type {
                self.delegate?.asn1Parser(self, didParse: .containerStart(type: type))
            }
            if !buffer.isEmpty {
                do {
                    var buffer = buffer
                    
                    while !buffer.isEmpty && !self.didAbort {
                        buffer = try self._parse(subdata: buffer)
                    }
                } catch let error {
                    shouldStopParsing = true
                    stopParsingError = error
                }
            }
            
            // did end container
            if let type = descriptor.tag.type {
                self.delegate?.asn1Parser(self, didParse: .containerEnd(type: type))
            }
        } else {
            do {
                guard let type = descriptor.tag.type else { throw Error.unknownASN1Type(descriptor.tag.rawType) }
                
                let value = try ASN1.value(convertedFrom: buffer, as: type)
                
                self.delegate?.asn1Parser(self, didParse: .value(value))
            } catch let error {
                shouldStopParsing = true
                stopParsingError = error
            }
        }
        
        if descriptor.domain == .contextSpecific {
            self.delegate?.asn1Parser(self, didParse: .contextEnd(type: descriptor.tag.rawType))
            // did end context with tag
        }
        
        if shouldStopParsing {
            throw stopParsingError
        }
        
        return subdata[buffer.endIndex...]
    }
}
