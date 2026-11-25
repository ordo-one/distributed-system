import DistributedABI

/// Nested struct mixing fixed-width fields with a (required) string — the long-sha case.
struct ResourceDataDescriptionLike {
    var generation: UInt64
    var partition: Int
    var offset: Int
    var totalChunks: UInt32
    var sha256: String
}
extension ResourceDataDescriptionLike: Equatable {}
extension ResourceDataDescriptionLike: Transferable {
    var transferSize: Int {
        self.generation.transferSize
            + self.partition.transferSize
            + self.offset.transferSize
            + self.totalChunks.transferSize
            + self.sha256.transferSize
    }

    func transfer(into output: inout TransferWriter) {
        self.generation.transfer(into: &output)
        self.partition.transfer(into: &output)
        self.offset.transfer(into: &output)
        self.totalChunks.transfer(into: &output)
        self.sha256.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(
            generation: try .init(transferring: &input),
            partition: try .init(transferring: &input),
            offset: try .init(transferring: &input),
            totalChunks: try .init(transferring: &input),
            sha256: try .init(transferring: &input)
        )
    }
}
