import DistributedABI

/// The measured bodies of the rows that ``RegisterStrings`` registers.
enum Strings {}
extension Strings {
    @inline(never) static func write<Value>(
        _ values: [Value],
        into frame: UnsafeMutableRawBufferPointer
    ) -> Int where Value: Transferable {
        //  no check of the room left before each value, as a container makes none: the output
        //  traps if the frame is too small
        var output: OutputRawSpan = .init(buffer: frame, initializedCount: 0)
        output.withTransferWriter {
            for value: Value in values {
                value.transfer(into: &$0)
            }
        }
        return output.finalize(for: frame)
    }

    /// The size pass alone.
    @inline(never) static func size<Value>(_ value: Value) -> Int where Value: Transferable {
        value.transferSize
    }

    /// The write pass alone, into a frame the caller sized for the value before the
    /// measurement.
    @inline(never) static func write<Value>(
        sized value: Value,
        into frame: UnsafeMutableRawBufferPointer
    ) -> Int where Value: Transferable {
        var output: OutputRawSpan = .init(buffer: frame, initializedCount: 0)
        output.withTransferWriter { value.transfer(into: &$0) }
        return output.finalize(for: frame)
    }

    /// The read pass alone, from a frame the write pass filled.
    @inline(never) static func read<Value>(
        _: Value.Type,
        from frame: UnsafeMutableRawBufferPointer,
        count: Int
    ) throws(TransferError) -> Value where Value: Transferable {
        var input: TransferReader = .init(
            unsafe UnsafeRawBufferPointer.init(rebasing: frame[..<count]).bytes
        )
        let value: Value = try .init(transferring: &input)
        try input.readEnd()
        return value
    }

    /// Writes `values` once as the row does, so we KNOW it fills exactly the frame it reserves
    /// with bytes that read back as the same strings, one after another, before measuring.
    static func writes<Value>(
        _ values: [Value],
        exactly capacity: Int
    ) -> Bool where Value: Transferable & Equatable {
        var bytes: [UInt8] = .init(repeating: 0, count: capacity)
        let count: Int = bytes.withUnsafeMutableBytes { Self.write(values, into: $0) }
        guard count == capacity else {
            return false
        }
        do {
            var input: TransferReader = .init(bytes.span.bytes)
            for value: Value in values {
                guard try Value.init(transferring: &input) == value else {
                    return false
                }
            }
            try input.readEnd()
            return true
        } catch {
            return false
        }
    }
}
