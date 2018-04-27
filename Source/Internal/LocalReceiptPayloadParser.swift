import Foundation

/// Parse a payload from a local App Store receipt file.
internal class LocalReceiptPayloadParser {
    private var parser: ASN1.Parser!
    private var payloadProcessor: ReceiptAttributeASN1SetProcessor!
    private var inAppPurchaseSetProcessor: ReceiptAttributeASN1SetProcessor!
    
    private var foundInAppPurchaseAttributes = [(InAppPurchaseReceiptAttributeType, ReceiptAttributeASN1SetProcessor.ReceiptAttribute)]()
    
    private var receiptEntries = [ReceiptEntry]()
    
    init() {
        
    }
    
    func receipt(from payload: Data) throws -> Receipt {
        self.payloadProcessor = ReceiptAttributeASN1SetProcessor(data: payload)
        self.payloadProcessor.delegate = self
        
        try self.payloadProcessor.start()
        
        // self.receiptEntries is populated in the processor delegate
        
        return ConstructedReceipt(from: self.receiptEntries)
    }
}

extension LocalReceiptPayloadParser {
    private enum PayloadReceiptAttributeType : Int {
        case bundleIdentifier = 2
        case applicationVersion = 3
        case opaqueValue = 4
        case sha1Hash = 5
        case inAppPurchase = 17
        case originalApplicationVersion = 19
        case creationDate = 12
        case expirationDate = 21
    }
    
    private enum InAppPurchaseReceiptAttributeType : Int {
        case quantity = 1701
        case productIdentifier = 1702
        case transactionIdentifier = 1703
        case originalTransactionIdentifier = 1705
        case purchaseDate = 1704
        case originalPurchaseDate = 1706
        case subscriptionExpirationDate = 1708
        case cancellationDate = 1712
        case webOrderLineItemIdentifier = 1711
    }
    
    private func processInAppPurchaseSet(_ data: Data) {
        self.foundInAppPurchaseAttributes.removeAll()
        
        self.inAppPurchaseSetProcessor = ReceiptAttributeASN1SetProcessor(data: data)
        self.inAppPurchaseSetProcessor.delegate = self
    
        do {
            try self.inAppPurchaseSetProcessor.start()
            
            var expiryDate: Date?
            var productIdentifier: String?
            
            for (type, attribute) in self.foundInAppPurchaseAttributes {
                switch type {
                    case .productIdentifier:
                        productIdentifier = attribute.stringValue
                    case .subscriptionExpirationDate:
                        expiryDate = attribute.stringValue.flatMap {
                            Date(fromISO8601: $0)
                        }
                    default:
                        break
                }
            }
            
            if let productIdentifier = productIdentifier {
                let entry = ReceiptEntry(productIdentifier: productIdentifier, expiryDate: expiryDate)
                self.receiptEntries.append(entry)
            }
        } catch let error {
            print(error)
        }
    }
    
    private func didFindPayloadReceiptAttribute(of attributeType: PayloadReceiptAttributeType, attribute: ReceiptAttributeASN1SetProcessor.ReceiptAttribute) {
        switch attributeType {
            case .inAppPurchase:
                self.processInAppPurchaseSet(attribute.rawBuffer)
            default:
                break
        }
    }
    
    private func didFindInAppPurchaseReceiptAttribute(of attributeType: InAppPurchaseReceiptAttributeType, attribute: ReceiptAttributeASN1SetProcessor.ReceiptAttribute) {
        self.foundInAppPurchaseAttributes.append((attributeType, attribute))
    }
}

extension LocalReceiptPayloadParser : ReceiptAttributeASN1SetProcessorDelegate {
    func receiptAttributeASN1SetProcessor(_ processor: ReceiptAttributeASN1SetProcessor, didFind attribute: ReceiptAttributeASN1SetProcessor.ReceiptAttribute) {
        switch processor {
            case self.payloadProcessor:
                if let attributeType = PayloadReceiptAttributeType(rawValue: attribute.type) {
                    self.didFindPayloadReceiptAttribute(of: attributeType, attribute: attribute)
                }
            case self.inAppPurchaseSetProcessor:
                if let attributeType = InAppPurchaseReceiptAttributeType(rawValue: attribute.type) {
                    self.didFindInAppPurchaseReceiptAttribute(of: attributeType, attribute: attribute)
                }
            default:
                MerchantKitFatalError.raise("undetected processor")
        }
    }
}
