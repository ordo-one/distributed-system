import DistributedABI

/// Order side — a simple raw-valued enum (buy / sell). Travels as its `UInt8` raw value.
enum SideLike: UInt8 {
    case buy = 0
    case sell = 1
}
extension SideLike: Transferable {}
