import DistributedABI

/// A value of one byte on the wire that states a discriminant layout but takes two bytes of
/// memory, which only a one-byte type can bear out: an array of them travels one element at a
/// time.
struct WideMark: Equatable, Transferable {
    let value: UInt8
    let spare: UInt8

    init(_ value: UInt8) {
        self.value = value
        self.spare = 0
    }

    static var transferLayout: TransferLayout? { .discriminant(count: 2) }
    var transferSize: Int { 1 }

    func transfer(into output: inout TransferWriter) {
        output.append(self.value)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        let byte: UInt8 = try input.readByte()
        guard byte < 2 else {
            throw .init(.invalidDiscriminant(.init(byte)))
        }
        self.init(byte)
    }
}
