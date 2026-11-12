import DistributedABI

/// A composite with padding between its fields, which states that it is stored as its transfer
/// bytes in the macro’s form: its offset check fails, so it does not.
struct InteriorPadding: Equatable, Transferable {
    let side: UInt8
    let price: Int64

    static var transferLayout: TransferLayout? {
        guard
        let side: TransferLayout = UInt8.transferLayout,
        let price: TransferLayout = Int64.transferLayout else {
            return nil
        }
        let size: Int = side.size + price.size
        guard
        case .bitwise = side,
        case .bitwise = price,
        MemoryLayout<Self>.offset(of: \Self.side) == 0,
        MemoryLayout<Self>.offset(of: \Self.price) == side.size,
        MemoryLayout<Self>.size == size else {
            return .fixed(size: size)
        }
        return .bitwise(size: size)
    }
    var transferSize: Int { 9 }

    func transfer(into output: inout TransferWriter) {
        self.side.transfer(into: &output)
        self.price.transfer(into: &output)
    }
    init(side: UInt8, price: Int64) {
        self.side = side
        self.price = price
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(side: try .init(transferring: &input), price: try .init(transferring: &input))
    }
}
