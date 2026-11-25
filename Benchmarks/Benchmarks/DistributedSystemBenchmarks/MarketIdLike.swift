import DistributedABI

/// `MarketId`-like nested fixed-width struct.
struct MarketIdLike {
    var value: UInt64
    var flags: UInt8
}
extension MarketIdLike: Equatable {}
extension MarketIdLike: Transferable {
    static var transferLayout: TransferLayout? { .fixed(size: 9) }
    var transferSize: Int { 9 }

    func transfer(into output: inout TransferWriter) {
        self.value.transfer(into: &output)
        self.flags.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        let value: UInt64 = try .init(transferring: &input)
        let flags: UInt8 = try .init(transferring: &input)
        self.init(value: value, flags: flags)
    }
}
