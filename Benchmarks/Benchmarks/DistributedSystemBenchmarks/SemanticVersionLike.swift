import DistributedABI

/// Semantic-version-like nested fixed-width struct.
struct SemanticVersionLike {
    var major: UInt16
    var minor: UInt16
    var patch: UInt16
    var preRelease: UInt16
}
extension SemanticVersionLike: Equatable {}
extension SemanticVersionLike: Transferable {
    static var transferLayout: TransferLayout? { .fixed(size: 8) }
    var transferSize: Int { 8 }

    func transfer(into output: inout TransferWriter) {
        self.major.transfer(into: &output)
        self.minor.transfer(into: &output)
        self.patch.transfer(into: &output)
        self.preRelease.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(
            major: try .init(transferring: &input),
            minor: try .init(transferring: &input),
            patch: try .init(transferring: &input),
            preRelease: try .init(transferring: &input)
        )
    }
}
