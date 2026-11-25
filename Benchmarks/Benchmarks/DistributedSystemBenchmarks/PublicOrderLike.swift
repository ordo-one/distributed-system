import DistributedABI

/// Hot-path book update. ~20 fields, the majority Optional fixed-width — the dominant real
/// shape.
struct PublicOrderLike {
    var identifier: UInt64
    var marketDataSource: UInt64?
    var market: MarketIdLike?
    var exchangeOrderReference: String?
    var instrument: UInt64
    var side: SideLike
    var price: Int64?
    var quantity: Int64?
    var state: UInt8?
    var count: Int?
    var priority: UInt64?
    var publicOrderTime: UInt64?
    var timeCreated: UInt64
    var timeUpdated: UInt64?
    var updatedByPlugin: UInt64?
    var updatedByModule: UInt64?
    var sourcePublicOrderRecoveryReference: String?
    var dateOfOrder: UInt32
    var type: OrderTypeLike?
}
extension PublicOrderLike {
    /// A realistic tick: most optionals nil, no strings, a plain `.limit` order. THE hot path.
    static func sparse(_ i: Int) -> Self {
        .init(
            identifier: 0x1000_0000_0000_0000 &+ UInt64.init(i),
            marketDataSource: nil,
            market: nil,
            exchangeOrderReference: nil,
            instrument: 13 &+ UInt64.init(i & 0xff),
            side: (i & 1 == 0) ? .buy : .sell,
            price: Int64.init(1_000_000 &+ i),
            quantity: Int64.init(100 &+ (i & 0x3ff)),
            state: nil,
            count: nil,
            priority: nil,
            publicOrderTime: nil,
            timeCreated: 0x1700_0000_0000_0000 &+ UInt64.init(i),
            timeUpdated: nil,
            updatedByPlugin: nil,
            updatedByModule: nil,
            sourcePublicOrderRecoveryReference: nil,
            dateOfOrder: 20_260_610,
            type: .limit
        )
    }

    /// Every optional populated, both strings 16 chars, a `.stopMarket` order.
    static func full(_ i: Int) -> Self {
        .init(
            identifier: 0x1000_0000_0000_0000 &+ UInt64.init(i),
            marketDataSource: 7,
            market: .init(value: 0xABCD_0000 &+ UInt64.init(i & 0xffff), flags: 0x03),
            exchangeOrderReference: "EXREF-0123456789",        // 16 chars
            instrument: 13 &+ UInt64.init(i & 0xff),
            side: (i & 1 == 0) ? .buy : .sell,
            price: Int64.init(1_000_000 &+ i),
            quantity: Int64.init(100 &+ (i & 0x3ff)),
            state: 3,
            count: 12,
            priority: 9_999,
            publicOrderTime: 0x1600_0000_0000_0000 &+ UInt64.init(i),
            timeCreated: 0x1700_0000_0000_0000 &+ UInt64.init(i),
            timeUpdated: 0x1701_0000_0000_0000 &+ UInt64.init(i),
            updatedByPlugin: 555,
            updatedByModule: 666,
            sourcePublicOrderRecoveryReference: "RECOV-9876543210",  // 16 chars
            dateOfOrder: 20_260_610,
            type: .stopMarket(stopPrice: Int64.init(990_000 &+ i))
        )
    }
}
extension PublicOrderLike: Equatable {}
extension PublicOrderLike: Transferable {
    var transferSize: Int {
        self.identifier.transferSize
            + self.marketDataSource.transferSize
            + self.market.transferSize
            + self.exchangeOrderReference.transferSize
            + self.instrument.transferSize
            + self.side.transferSize
            + self.price.transferSize
            + self.quantity.transferSize
            + self.state.transferSize
            + self.count.transferSize
            + self.priority.transferSize
            + self.publicOrderTime.transferSize
            + self.timeCreated.transferSize
            + self.timeUpdated.transferSize
            + self.updatedByPlugin.transferSize
            + self.updatedByModule.transferSize
            + self.sourcePublicOrderRecoveryReference.transferSize
            + self.dateOfOrder.transferSize
            + self.type.transferSize
    }

    func transfer(into output: inout TransferWriter) {
        self.identifier.transfer(into: &output)
        self.marketDataSource.transfer(into: &output)
        self.market.transfer(into: &output)
        self.exchangeOrderReference.transfer(into: &output)
        self.instrument.transfer(into: &output)
        self.side.transfer(into: &output)
        self.price.transfer(into: &output)
        self.quantity.transfer(into: &output)
        self.state.transfer(into: &output)
        self.count.transfer(into: &output)
        self.priority.transfer(into: &output)
        self.publicOrderTime.transfer(into: &output)
        self.timeCreated.transfer(into: &output)
        self.timeUpdated.transfer(into: &output)
        self.updatedByPlugin.transfer(into: &output)
        self.updatedByModule.transfer(into: &output)
        self.sourcePublicOrderRecoveryReference.transfer(into: &output)
        self.dateOfOrder.transfer(into: &output)
        self.type.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(
            identifier: try .init(transferring: &input),
            marketDataSource: try .init(transferring: &input),
            market: try .init(transferring: &input),
            exchangeOrderReference: try .init(transferring: &input),
            instrument: try .init(transferring: &input),
            side: try .init(transferring: &input),
            price: try .init(transferring: &input),
            quantity: try .init(transferring: &input),
            state: try .init(transferring: &input),
            count: try .init(transferring: &input),
            priority: try .init(transferring: &input),
            publicOrderTime: try .init(transferring: &input),
            timeCreated: try .init(transferring: &input),
            timeUpdated: try .init(transferring: &input),
            updatedByPlugin: try .init(transferring: &input),
            updatedByModule: try .init(transferring: &input),
            sourcePublicOrderRecoveryReference: try .init(transferring: &input),
            dateOfOrder: try .init(transferring: &input),
            type: try .init(transferring: &input)
        )
    }
}
