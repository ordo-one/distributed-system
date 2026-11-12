import DistributedABI

/// The same enumeration with no statement, read one element at a time: the reference the
/// checked copy is compared against.
enum UnstatedMark: UInt8, CaseIterable, Equatable, Transferable {
    case none
    case near
    case at
}
