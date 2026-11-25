import DistributedABI

/// Order type — an enum with associated values: a `UInt8` discriminant in declaration order
/// followed by the associated value of the selected case.
enum OrderTypeLike {
    case market
    case limit
    case stopMarket(stopPrice: Int64)
    case peg(offsetTicks: Int)
}
extension OrderTypeLike: Equatable {}
extension OrderTypeLike: Transferable {
    var transferSize: Int {
        switch self {
        case .market, .limit: 1
        case .stopMarket: 9
        case .peg: 9
        }
    }

    func transfer(into output: inout TransferWriter) {
        switch self {
        case .market:
            output.append(0)
        case .limit:
            output.append(1)
        case .stopMarket(let stopPrice):
            output.append(2)
            stopPrice.transfer(into: &output)
        case .peg(let offsetTicks):
            output.append(3)
            offsetTicks.transfer(into: &output)
        }
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        switch try input.readByte() {
        case 0: self = .market
        case 1: self = .limit
        case 2: self = .stopMarket(stopPrice: try .init(transferring: &input))
        case 3: self = .peg(offsetTicks: try .init(transferring: &input))
        case let code: throw .init(.invalidDiscriminant(.init(code)))
        }
    }
}
