import Benchmark
import DistributedABI

/// The measured bodies of the rows that ``Payloads.register()`` registers.
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
extension Payloads {
    /// PRODUCTION-REPRESENTATIVE serialization payloads.
    ///
    /// A payload census of the real data model (~/GitHub/package-data-model) found 1691 fields
    /// that are 66% Optional, 11% String, 10% Array, and ZERO Dictionary/Set. The existing
    /// suite only measures 10001-element arrays of isolated Int / String / Dictionary — none of
    /// which resemble a real message. The replica types measured here (``PublicOrderLike``,
    /// ``ResourceLike`` and ``ComputedPropertySubscriptionLike``, with the types they nest)
    /// mirror the real shapes: structs of mixed fixed-width + optional + short-string fields,
    /// plus a few identifier-array collections.
    ///
    /// These are SELF-CONTAINED replicas with NO SDK dependency, and their `Transferable`
    /// conformances are written the way a hand-written composite conforms in DistributedABI
    /// 8.0:
    ///   * a struct writes each stored field in declaration order through `transfer(into:)`,
    ///     and reads it back in the same order through `init(transferring:)`: every value
    ///     delimits itself, so the struct writes nothing around a field;
    ///   * a struct whose fields all have a fixed size states the sum as its own fixed size;
    ///   * Optional   = 1 discriminant byte (0 = none, 1 = some) then the wrapped value if
    ///     some;
    ///   * fixed-width integer = little-endian raw bytes;
    ///   * String     = a ULEB128 length, then the UTF-8 bytes;
    ///   * enum (raw) = the UInt8 raw value, through the library’s `RawRepresentable` default;
    ///   * enum (associated values) = UInt8 discriminant then the payload, as `Optional` and
    ///     `Result` do;
    ///   * Collection = ULEB128 count then each element one after another.
    ///
    /// Every row here is `Composite`. Nothing in ordo or the plugins conforms a composite by
    /// hand today: in production these shapes travel as SBE messages, which lend their bytes
    /// unchanged. A hand-written composite is the form a binary path from plugin to plugin
    /// would take, and the replicas measure what one that serializes field by field costs.
    static func register() {
        let configuration: Benchmark.Configuration = .init(
            metrics: .default,
            timeUnits: .microseconds
        )

        // Build fixture arrays ONCE (outside the measured region). 1000 messages per iteration
        // so the per-message work dominates the loop overhead.
        let messageCount: Int = 1_000

        func register<Payload>(_ name: String, _ messages: [Payload], frame capacity: Int)
            where Payload: Transferable & Equatable {
            precondition(messages[0].roundtrips, "\(name) roundtrip mismatch")
            Benchmark.init(name, configuration: configuration) { (benchmark: Benchmark) in
                let frame: UnsafeMutableRawBufferPointer = .allocate(
                    byteCount: capacity,
                    alignment: 16
                )
                defer {
                    frame.deallocate()
                }
                benchmark.startMeasurement()
                for _: Int in benchmark.scaledIterations {
                    try Self.roundtrip(messages, frame: frame)
                }
            }
        }

        // -- PublicOrderLike sparse (the true hot path) --
        register(
            "Composite PublicOrder sparse",
            (0 ..< messageCount).map(PublicOrderLike.sparse),
            frame: 256
        )
        // -- PublicOrderLike full (every optional populated, two 16-char strings) --
        register(
            "Composite PublicOrder full",
            (0 ..< messageCount).map(PublicOrderLike.full),
            frame: 256
        )
        // -- ResourceLike (strings + optionals + nested) --
        register(
            "Composite Resource",
            (0 ..< messageCount).map(ResourceLike.sample),
            frame: 512
        )

        // -- ComputedPropertySubscriptionLike across object counts (Big-O slope) --
        //  Each settings value on its own as well, so that a value which reads other than it
        //  writes is named here rather than found as a mismatch somewhere later in the message.
        for setting: PropertyLike in PropertyLike.settings {
            precondition(setting.value.roundtrips, "\(setting.value) roundtrip mismatch")
        }
        //  Fewer messages per iteration for the large object counts so total work per iteration
        //  stays bounded; per-element instructions are derived from the slope across counts.
        for objectCount: Int in [10, 100, 1_000, 10_000] {
            let messages: Int = objectCount >= 1_000 ? 50 : 200
            register(
                "Composite CPSub objects=\(objectCount)",
                (0 ..< messages).map {
                    ComputedPropertySubscriptionLike.sample(objectCount: objectCount, $0)
                },
                frame: objectCount * 9 + 256
            )
        }
    }
}
