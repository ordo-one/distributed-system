import DistributedABI
import Synchronization

/// The same probe with no statement, whose every element goes through its conformance: the
/// reference that shows the probe counts.
enum UnstatedTally: UInt8, CaseIterable, Equatable, Transferable {
    case zero
    case one
    case two

    static let reads: Atomic<Int> = .init(0)
    static let writes: Atomic<Int> = .init(0)

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
