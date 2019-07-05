import Foundation

/// Parse a payload from a local App Store receipt file.
internal class LocalReceiptPayloadParser {
    private var payloadProcessor: ReceiptAttributeASN1SetProcessor!
    private var inAppPurchaseSetProcessor: ReceiptAttributeASN1SetProcessor!

    private var foundInAppPurchaseAttributes = [(InAppPurchaseReceiptAttributeType, ReceiptAttributeASN1SetProcessor.ReceiptAttribute)]()
    private var encounteredInAppPurchaseProcessorError: Error?

    private var receiptEntries = [ReceiptEntry]()
    private var metadataBuilder = ReceiptMetadataBuilder()

    init() {

    }

    func receipt(from payload: Data) throws -> Receipt {
        self.reset()

        self.inAppPurchaseSetProcessor = nil

        self.payloadProcessor = ReceiptAttributeASN1SetProcessor(data: payload)
        self.payloadProcessor.delegate = self

        try self.payloadProcessor.start()

        // if there are no receipt entries, then check to see if we hit an error in the sub-processor before proceeding
        if self.receiptEntries.isEmpty, let error = self.encounteredInAppPurchaseProcessorError {
            throw error
        }

        // self.metadataBuilder is populated with available fields

        let metadata = self.metadataBuilder.build()

        // self.receiptEntries is populated in the processor delegate

        return ConstructedReceipt(from: self.receiptEntries, metadata: metadata)
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

    private func reset() {
        self.payloadProcessor = nil
        self.inAppPurchaseSetProcessor = nil

        self.resetInAppPurchaseProcessIntermediaryValues()
        self.encounteredInAppPurchaseProcessorError = nil

        self.receiptEntries.removeAll()
        self.metadataBuilder = ReceiptMetadataBuilder()
    }

    private func resetInAppPurchaseProcessIntermediaryValues() {
        self.foundInAppPurchaseAttributes.removeAll()
    }

    private func processInAppPurchaseSet(_ data: Data) {
        self.resetInAppPurchaseProcessIntermediaryValues()

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
                        expiryDate = attribute.iso8601DateValue
                    default:
                        break
                }
            }

            if let productIdentifier = productIdentifier {
                let entry = ReceiptEntry(productIdentifier: productIdentifier, expiryDate: expiryDate)
                self.receiptEntries.append(entry)
            }
        } catch let error {
            self.encounteredInAppPurchaseProcessorError = error
        }
    }

    private func didFindPayloadReceiptAttribute(of attributeType: PayloadReceiptAttributeType, attribute: ReceiptAttributeASN1SetProcessor.ReceiptAttribute) {
        switch attributeType {
            case .inAppPurchase:
                self.processInAppPurchaseSet(attribute.rawBuffer)
            case .originalApplicationVersion:
                self.metadataBuilder.originalApplicationVersion = attribute.stringValue ?? ""
            case .bundleIdentifier:
                self.metadataBuilder.bundleIdentifier = attribute.stringValue ?? ""
            case .creationDate:
                self.metadataBuilder.creationDate = attribute.iso8601DateValue
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
            MerchantKitFatalError.raise("The `LocalReceiptPayloadParser` faced an unexpected `processor` and does not know how to handle it.")
        }
    }
}
