import DistributedABI

/// The same composite as ``Pair`` with no statement, read one element at a time: the reference
/// its copy is compared against.
struct UnstatedPair: Equatable {
    let low: UInt32
    let high: UInt32

    init(low: UInt32, high: UInt32) {
        self.low = low
        self.high = high
    }
}
extension UnstatedPair: Transferable {
    static var transferLayout: TransferLayout? { .fixed(size: 8) }
    var transferSize: Int { 8 }

    func transfer(into output: inout TransferWriter) {
        self.low.transfer(into: &output)
        self.high.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(low: try .init(transferring: &input), high: try .init(transferring: &input))
    }
}
