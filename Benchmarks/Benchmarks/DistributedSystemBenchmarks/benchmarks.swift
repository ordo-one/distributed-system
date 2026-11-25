import Benchmark

//  Each row is named by the production role of the values it measures, so the raw output reads
//  on its own: `Standard` for the standard types ordo sends (integers, strings, collections of
//  them, and the dictionary of the cache synchronization endpoint), `SBE` for values that lend
//  bytes they already hold, as an SBE message does, `Built on lend` for values that build their
//  bytes on every lend, as a value that travels as its JSON does, and `Composite` for the
//  hand-written composites that Payloads.swift registers. The round trips of Roundtrips.swift
//  are all `Standard`.

//  Each group declares its `register()` after the functions its rows measure. The optimizer
//  can specialize a generic function before it has optimized it, when the only call reaches it
//  from a closure declared earlier, and the specialization of `Payloads.roundtrip(_:frame:)`
//  then copies every message it reads.

// Not main-actor isolated: the harness calls it from its nonisolated `registerBenchmarks()`,
// which Swift 6.4 refuses for a main-actor `let`.
let benchmarks: @Sendable () -> () = {
    Benchmark.defaultConfiguration.timeUnits = .microseconds
    Benchmark.defaultConfiguration.units = [
        .instructions: .kilo,
        .throughput: .count,
    ]

    // Round trips of the standard types (see Roundtrips.swift).
    Roundtrips.register()
    // The write and the read of `Standard RoundtripDictionary?` apart (see Dictionaries.swift).
    Dictionaries.register()
    // Production-representative payload benchmarks (see Payloads.swift).
    Payloads.register()
    // String writes on their own (see Strings.swift).
    Strings.register()
    // Sends of class-backed messages (see Sends.swift).
    Sends.register()
}
