import DistributedABI

/// A composite that states it is stored as its transfer bytes although it is not: nine bytes on
/// the wire, a stride of sixteen in memory. An array of them must travel one element at a time.
struct TrailingPadding: Equatable, Transferable {
    let price: Int64
    let side: UInt8

    static var transferLayout: TransferLayout? { .bitwise(size: 9) }
    var transferSize: Int { 9 }

    func transfer(into output: inout TransferWriter) {
        self.price.transfer(into: &output)
        self.side.transfer(into: &output)
    }
    init(price: Int64, side: UInt8) {
        self.price = price
        self.side = side
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(price: try .init(transferring: &input), side: try .init(transferring: &input))
    }
}
