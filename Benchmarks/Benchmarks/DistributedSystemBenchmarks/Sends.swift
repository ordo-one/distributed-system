import DistributedABI

/// The measured bodies of the rows that ``RegisterSends`` registers.
enum Sends {}
extension Sends {
    @inline(never) static func send<Value>(
        _ value: Value,
        into frame: UnsafeMutableRawBufferPointer
    ) -> Int where Value: Transferable {
        let size: Int = value.transferSize
        precondition(size <= frame.count, "frame too small")
        let buffer: UnsafeMutableRawBufferPointer = .init(rebasing: frame[..<size])
        var output: OutputRawSpan = .init(buffer: buffer, initializedCount: 0)
        output.withTransferWriter { value.transfer(into: &$0) }
        return output.finalize(for: buffer)
    }

    @inline(never) static func receive<Value>(
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
}
