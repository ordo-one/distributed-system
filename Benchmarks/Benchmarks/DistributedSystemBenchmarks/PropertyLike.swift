import DistributedABI

/// A single property: identifier + value.
struct PropertyLike {
    var identifier: UInt64
    var value: PropertyValueLike
}
extension PropertyLike {
    /// ~8 settings of mixed PropertyValue cases.
    static var settings: [Self] {
        [
            .init(identifier: 1, value: .integer(13)),
            .init(identifier: 2, value: .decimal(123_456)),
            .init(identifier: 3, value: .boolean(true)),
            .init(identifier: 4, value: .text("status-ok")),
            .init(identifier: 5, value: .timestamp(0x1700_0000_0000_0000)),
            .init(identifier: 6, value: .instrument(987_654)),
            .init(identifier: 7, value: .integer(-9)),
            .init(identifier: 8, value: .text("hello-world-tag")),
        ]
    }
}
extension PropertyLike: Equatable {}
extension PropertyLike: Transferable {
    var transferSize: Int {
        self.identifier.transferSize + self.value.transferSize
    }

    func transfer(into output: inout TransferWriter) {
        self.identifier.transfer(into: &output)
        self.value.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(
            identifier: try .init(transferring: &input),
            value: try .init(transferring: &input)
        )
    }
}
