import DistributedABI

/// An enumeration with no payload and implicit raw values, its case indices, which states its
/// case count: an array of them travels as one copy of its storage, each byte checked.
enum Mark: UInt8, CaseIterable, Equatable, Transferable {
    case none
    case near
    case at

    static var transferLayout: TransferLayout? { .discriminant(count: 3) }
}
