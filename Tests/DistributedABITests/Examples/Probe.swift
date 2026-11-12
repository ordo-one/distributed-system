import DistributedABI

/// A wrapper that states it is stored as its transfer bytes but writes and reads itself, one at a
/// time, big-endian: a probe, which shows which path an array took, since the copy of its storage
/// is little-endian on a little-endian host.
struct Probe: Equatable, Transferable {
    let value: UInt64

    static var transferLayout: TransferLayout? { UInt64.transferLayout }
    var transferSize: Int { 8 }

    func transfer(into output: inout TransferWriter) {
        self.value.bigEndian.transfer(into: &output)
    }
    init(_ value: UInt64) {
        self.value = value
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(UInt64.init(bigEndian: try .init(transferring: &input)))
    }
}
