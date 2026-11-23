import DistributedABI

/// `Bool`’s wire form under a type that states no number of discriminants, read one element at
/// a time: the reference the checked copy of `Bool` is compared against.
struct UnstatedFlag: Equatable {
    let value: Bool

    init(_ value: Bool) {
        self.value = value
    }
}
extension UnstatedFlag: Transferable {
    static var transferLayout: TransferLayout? { .fixed(size: 1) }
    var transferSize: Int { 1 }

    func transfer(into output: inout TransferWriter) {
        self.value.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(try .init(transferring: &input))
    }
}
