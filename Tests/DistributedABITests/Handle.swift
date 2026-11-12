import DistributedABI

/// A value of eight bytes in memory that holds a reference, and states, wrongly, that it is stored
/// as its transfer bytes. The collections refuse to copy its memory, which would copy the reference
/// without retaining it, and write and read it one element at a time.
struct Handle: Equatable, Transferable {
    let box: Box

    static func == (a: Self, b: Self) -> Bool { a.box.value == b.box.value }

    static var transferLayout: TransferLayout? { .bitwise(size: 8) }
    var transferSize: Int { 8 }

    func transfer(into output: inout TransferWriter) {
        self.box.value.transfer(into: &output)
    }
    init(_ value: UInt64) {
        self.box = .init(value: value)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(try UInt64.init(transferring: &input))
    }
}
