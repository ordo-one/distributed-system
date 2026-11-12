import DistributedABI

/// A wrapper of one `UInt64`, as the SDK’s identifiers are, that states it is stored as its
/// transfer bytes by forwarding its raw value’s answer: an array of them travels as one copy.
struct Ticket: Equatable, RawRepresentable, Transferable {
    let rawValue: UInt64

    init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    static var transferLayout: TransferLayout? { RawValue.transferLayout }
}
