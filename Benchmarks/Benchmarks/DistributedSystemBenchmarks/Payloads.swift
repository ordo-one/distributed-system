import Benchmark
import DistributedABI

/// The measured bodies of the rows that ``RegisterPayloads`` registers.
enum Payloads {}
extension Payloads {
    //  The measured region models the 8.0 transport path: the message is sized from
    //  `transferSize`, written straight into one reused frame buffer (the send, no intermediate
    //  copy), and read back from that buffer through a borrowed reader (the receive, no decoder
    //  copy). `blackHole` keeps the decoded value live. The 7.x suite also measured “nocopy”
    //  variants that left out its two buffer copies; 8.0 has neither copy, so they are gone.
    @inline(never) static func roundtrip<Payload>(
        _ messages: [Payload],
        frame: UnsafeMutableRawBufferPointer
    ) throws(TransferError) where Payload: Transferable {
        for message: Payload in messages {
            precondition(message.transferSize <= frame.count, "frame too small")
            var output: OutputRawSpan = .init(buffer: frame, initializedCount: 0)
            output.withTransferWriter { message.transfer(into: &$0) }
            do {
                var input: TransferReader = .init(output.bytes)
                let value: Payload = try .init(transferring: &input)
                try input.readEnd()
                blackHole(value)
            }
            _ = output.finalize(for: frame)
        }
    }
}
