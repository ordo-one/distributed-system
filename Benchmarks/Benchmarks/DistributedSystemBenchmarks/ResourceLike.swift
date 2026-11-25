import DistributedABI

/// Strings + optionals + nested struct — exercises the String fastpath heavily.
struct ResourceLike {
    var identifier: UInt64
    var state: UInt8
    var version: SemanticVersionLike
    var sha256: String?
    var symbol: String
    var name: String?
    var originalFilesystemName: String?
    var timeCreated: UInt64
    var timeUpdated: UInt64?
    var dataDescription: ResourceDataDescriptionLike?
}
extension ResourceLike {
    static func sample(_ i: Int) -> Self {
        .init(
            identifier: 0x2000_0000_0000_0000 &+ UInt64.init(i),
            state: 2,
            version: .init(major: 1, minor: 4, patch: 17, preRelease: 0),
            sha256: String.init(repeating: "0123456789abcdef", count: 4),  // 64 hex
            symbol: "AAPL.OQ\(i & 1)",  // 8 chars
            name: "Apple Inc Common Stock",
            originalFilesystemName: "aapl-quote-feed.bin",
            timeCreated: 0x1700_0000_0000_0000 &+ UInt64.init(i),
            timeUpdated: 0x1701_0000_0000_0000 &+ UInt64.init(i),
            dataDescription: .init(
                generation: 3,
                partition: 7,
                offset: 1_048_576,
                totalChunks: 64,
                sha256: "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
            )
        )
    }
}
extension ResourceLike: Equatable {}
extension ResourceLike: Transferable {
    var transferSize: Int {
        self.identifier.transferSize
            + self.state.transferSize
            + self.version.transferSize
            + self.sha256.transferSize
            + self.symbol.transferSize
            + self.name.transferSize
            + self.originalFilesystemName.transferSize
            + self.timeCreated.transferSize
            + self.timeUpdated.transferSize
            + self.dataDescription.transferSize
    }

    func transfer(into output: inout TransferWriter) {
        self.identifier.transfer(into: &output)
        self.state.transfer(into: &output)
        self.version.transfer(into: &output)
        self.sha256.transfer(into: &output)
        self.symbol.transfer(into: &output)
        self.name.transfer(into: &output)
        self.originalFilesystemName.transfer(into: &output)
        self.timeCreated.transfer(into: &output)
        self.timeUpdated.transfer(into: &output)
        self.dataDescription.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(
            identifier: try .init(transferring: &input),
            state: try .init(transferring: &input),
            version: try .init(transferring: &input),
            sha256: try .init(transferring: &input),
            symbol: try .init(transferring: &input),
            name: try .init(transferring: &input),
            originalFilesystemName: try .init(transferring: &input),
            timeCreated: try .init(transferring: &input),
            timeUpdated: try .init(transferring: &input),
            dataDescription: try .init(transferring: &input)
        )
    }
}
