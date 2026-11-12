import DistributedABI

/// The same wrapper with no statement, so that an array of them travels one element at a time:
/// the reference the bulk path is compared against.
struct UnstatedTicket: Equatable, RawRepresentable, Transferable {
    let rawValue: UInt64

    init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}
