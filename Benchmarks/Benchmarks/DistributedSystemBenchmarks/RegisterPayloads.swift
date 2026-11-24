import Benchmark
import DistributedABI

/// PRODUCTION-REPRESENTATIVE serialization payloads.
///
/// A payload census of the real data model (~/GitHub/package-data-model) found 1691 fields
/// that are 66% Optional, 11% String, 10% Array, and ZERO Dictionary/Set. The existing suite
/// only measures 10001-element arrays of isolated Int / String / Dictionary — none of which
/// resemble a real message. The replica types measured here (``PublicOrderLike``,
/// ``ResourceLike`` and ``ComputedPropertySubscriptionLike``, with the types they nest) mirror
/// the real shapes: structs of mixed fixed-width + optional + short-string fields, plus a few
/// identifier-array collections.
///
/// These are SELF-CONTAINED replicas with NO SDK dependency, and their `Transferable`
/// conformances are written the way a hand-written composite conforms in DistributedABI 8.0:
///   * a struct writes each stored field in declaration order through `transfer(into:)`, and
///     reads it back in the same order through `init(transferring:)`: every value delimits
///     itself, so the struct writes nothing around a field;
///   * a struct whose fields all have a fixed size states the sum as its own fixed size;
///   * Optional   = 1 discriminant byte (0 = none, 1 = some) then the wrapped value if some;
///   * fixed-width integer = little-endian raw bytes;
///   * String     = a ULEB128 length, then the UTF-8 bytes;
///   * enum (raw) = the UInt8 raw value, through the library’s `RawRepresentable` default;
///   * enum (associated values) = UInt8 discriminant then the payload, as `Optional` and
///     `Result` do;
///   * Collection = ULEB128 count then each element one after another.
///
/// Every row here is `Composite`. Nothing in ordo or the plugins conforms a composite by hand
/// today: in production these shapes travel as SBE messages, which lend their bytes unchanged.
/// A hand-written composite is the form a binary path from plugin to plugin would take, and the
/// replicas measure what one that serializes field by field costs.
func RegisterPayloads() {
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
                try Payloads.roundtrip(messages, frame: frame)
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
