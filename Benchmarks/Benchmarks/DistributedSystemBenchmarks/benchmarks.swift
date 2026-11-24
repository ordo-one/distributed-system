import Benchmark

//  Each row is named by the production role of the values it measures, so the raw output reads
//  on its own: `Standard` for the standard types ordo sends (integers, strings, collections of
//  them, and the dictionary of the cache synchronization endpoint), `SBE` for values that lend
//  bytes they already hold, as an SBE message does, `Built on lend` for values that build their
//  bytes on every lend, as a value that travels as its JSON does, and `Composite` for the
//  hand-written composites that RegisterPayloads.swift registers. The round trips of
//  RegisterRoundtrips.swift are all `Standard`.

// Not main-actor isolated: the harness calls it from its nonisolated `registerBenchmarks()`,
// which Swift 6.4 refuses for a main-actor `let`.
let benchmarks: @Sendable () -> () = {
    Benchmark.defaultConfiguration.timeUnits = .microseconds
    Benchmark.defaultConfiguration.units = [
        .instructions: .kilo,
        .throughput: .count,
    ]

    // Round trips of the standard types (see RegisterRoundtrips.swift).
    RegisterRoundtrips()
    // The write and the read of `Standard RoundtripDictionary?` apart
    // (see RegisterDictionaries.swift).
    RegisterDictionaries()
    // Production-representative payload benchmarks (see RegisterPayloads.swift).
    RegisterPayloads()
    // String writes on their own (see RegisterStrings.swift).
    RegisterStrings()
    // Sends of class-backed messages (see RegisterSends.swift).
    RegisterSends()
}
