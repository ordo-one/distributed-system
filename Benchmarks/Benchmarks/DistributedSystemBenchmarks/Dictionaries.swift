import DistributedABI

/// The measured bodies of the rows that ``RegisterDictionaries`` registers.
enum Dictionaries {}
extension Dictionaries {
    //  The read half of the dictionary round trip: each value is read back from its own
    //  `[UInt8]`, written before the measurement.
    @inline(never) static func read<Value>(
        _ frames: [[UInt8]],
        as _: Value.Type
    ) throws(TransferError) -> [Value] where Value: Transferable {
        try frames.map { (frame: [UInt8]) throws(TransferError) -> Value in
            try .decode(frame)
        }
    }

    /// 101 dictionaries of 101 entries each, representative of
    /// CacheSynchronizationClientEndpoint as those of `RoundtripDictionary?` are: every entry
    /// maps the same 101 strings to integers that depend only on where they are, rather than to
    /// random ones.
    static func values() -> [[Int: [String: Int]]?] {
        let strings: [String] = (0 ... 100).map { String.init($0 * 131989, radix: 16) }
        let dictionaries: [[Int: [String: Int]]?] = (0 ... 100).map { (i: Int) in
            (0 ... 100).reduce(into: [:]) { (dictionary: inout [Int: [String: Int]], j: Int) in
                dictionary[j] = strings.indices.reduce(into: [:]) {
                    let k: UInt64 = .init((i * 101 + j) * 101 + $1)
                    let value: Int = .init(truncatingIfNeeded: k &* 0x9e37_79b9_7f4a_7c15)
                    $0[strings[$1]] = value
                }
            }
        }
        precondition(dictionaries[0].roundtrips, "dictionary roundtrip mismatch")
        return dictionaries
    }
}
