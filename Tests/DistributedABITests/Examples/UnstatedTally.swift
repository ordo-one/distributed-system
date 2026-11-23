import DistributedABI
import Synchronization

/// The same probe with no statement, whose every element goes through its conformance: the
/// reference that shows the probe counts.
enum UnstatedTally: UInt8, CaseIterable, Equatable {
    case zero
    case one
    case two
}
extension UnstatedTally {
    static let reads: Atomic<Int> = .init(0)
    static let writes: Atomic<Int> = .init(0)
}
extension UnstatedTally: Transferable {
    func transfer(into output: inout TransferWriter) {
        Self.writes.add(1, ordering: .relaxed)
        output.append(self.rawValue)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        Self.reads.add(1, ordering: .relaxed)
        let byte: UInt8 = try input.readByte()
        guard
        let value: Self = .init(rawValue: byte) else {
            throw .init(.invalidDiscriminant(.init(byte)))
        }
        self = value
    }
}
