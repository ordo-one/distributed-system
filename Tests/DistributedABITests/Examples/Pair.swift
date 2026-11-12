import DistributedABI

/// A composite of two `UInt32`, which states that it is stored as its transfer bytes as the
/// `@Transferable` macro planned for plugin-to-plugin calls would: from its fields’ own
/// statements and its layout, checked in code.
struct Pair: Equatable {
    let low: UInt32
    let high: UInt32

    init(low: UInt32, high: UInt32) {
        self.low = low
        self.high = high
    }
}
extension Pair: Transferable {
    static var transferLayout: TransferLayout? {
        guard
        let low: TransferLayout = UInt32.transferLayout,
        let high: TransferLayout = UInt32.transferLayout else {
            return nil
        }
        let size: Int = low.size + high.size
        guard
        case .bitwise = low,
        case .bitwise = high,
        MemoryLayout<Self>.offset(of: \Self.low) == 0,
        MemoryLayout<Self>.offset(of: \Self.high) == low.size,
        MemoryLayout<Self>.size == size else {
            return .fixed(size: size)
        }
        return .bitwise(size: size)
    }
    var transferSize: Int { self.low.transferSize + self.high.transferSize }

    func transfer(into output: inout TransferWriter) {
        self.low.transfer(into: &output)
        self.high.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(low: try .init(transferring: &input), high: try .init(transferring: &input))
    }
}
