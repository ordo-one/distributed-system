import DistributedABI

/// The measured bodies of the rows that ``RegisterRoundtrips`` registers.
enum Roundtrips {}
extension Roundtrips {
    //  Each value is written into one frame allocated before the measurement and read back from
    //  it, as the transport writes a value into a frame and reads it from there, so the row
    //  counts the codec and not an allocation per value.
    @inline(never) static func roundtrip<Value>(
        _ values: [Value],
        frame: UnsafeMutableRawBufferPointer
    ) throws(TransferError) -> [Value] where Value: Transferable {
        try values.map { (value: Value) throws(TransferError) -> Value in
            var output: OutputRawSpan = .init(buffer: frame, initializedCount: 0)
            output.withTransferWriter { value.transfer(into: &$0) }
            let decoded: Value
            do {
                var input: TransferReader = .init(output.bytes)
                decoded = try .init(transferring: &input)
                try input.readEnd()
            }
            _ = output.finalize(for: frame)
            return decoded
        }
    }

    //  The whole batch travels as one array in one buffer: a count, then the elements one after
    //  another, the integers packed and each string behind its own length.
    @inline(never) static func roundtrip<Value>(
        batch values: [Value]
    ) throws(TransferError) -> [Value] where Value: Transferable {
        try .decode(.init(transferring: values))
    }
}
