import DistributedABI

extension Transferable {
    /// Reads one value from all of `bytes`, refusing any byte left over.
    @inlinable static func decode(_ bytes: [UInt8]) throws(TransferError) -> Self {
        var input: TransferReader = .init(bytes.span.bytes)
        let value: Self = try .init(transferring: &input)
        try input.readEnd()
        return value
    }
}
extension Transferable where Self: Equatable {
    /// A quick round-trip validation used at fixture-build time so we KNOW the conformance
    /// agrees with itself, writes exactly the bytes it states, and reads exactly those bytes
    /// back when more follow them, as every value must, since nothing around it marks where it
    /// ends, before measuring.
    var roundtrips: Bool {
        let bytes: [UInt8] = .init(transferring: self)
        guard bytes.count == self.transferSize else {
            return false
        }
        do {
            guard try Self.decode(bytes) == self else {
                return false
            }
            //  the same bytes twice over: the first read must stop where the second begins
            let twice: [UInt8] = bytes + bytes
            var input: TransferReader = .init(twice.span.bytes)
            let first: Self = try .init(transferring: &input)
            let second: Self = try .init(transferring: &input)
            try input.readEnd()
            return first == self && second == self
        } catch {
            return false
        }
    }
}
