import Benchmark
import DistributedABI

/// The measured bodies of the rows that ``Roundtrips.register()`` registers.
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
extension Roundtrips {
    static func register() {
        Benchmark.init(
            "Standard RoundtripInt",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            let ints: [Int] = .init(0 ... 10000)
            let frame: UnsafeMutableRawBufferPointer = .allocate(
                byteCount: ints.reduce(0) { max($0, $1.transferSize) },
                alignment: 16
            )
            defer {
                frame.deallocate()
            }

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(ints, frame: frame))
            }
        }
        Benchmark.init(
            "Standard RoundtripInt?",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            let ints: [Int?] = (0 ... 10000).map { $0 }
            let frame: UnsafeMutableRawBufferPointer = .allocate(
                byteCount: ints.reduce(0) { max($0, $1.transferSize) },
                alignment: 16
            )
            defer {
                frame.deallocate()
            }

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(ints, frame: frame))
            }
        }
        Benchmark.init(
            "Standard RoundtripString",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            let strings: [String] = (0 ... 10000).map { String.init($0 * 131989, radix: 16) }
            let frame: UnsafeMutableRawBufferPointer = .allocate(
                byteCount: strings.reduce(0) { max($0, $1.transferSize) },
                alignment: 16
            )
            defer {
                frame.deallocate()
            }

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(strings, frame: frame))
            }
        }
        Benchmark.init(
            "Standard RoundtripString?",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            let strings: [String?] = (0 ... 10000).map { String.init($0 * 131989, radix: 16) }
            let frame: UnsafeMutableRawBufferPointer = .allocate(
                byteCount: strings.reduce(0) { max($0, $1.transferSize) },
                alignment: 16
            )
            defer {
                frame.deallocate()
            }

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(strings, frame: frame))
            }
        }
        Benchmark.init(
            "Standard RoundtripIntBatch",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            let ints: [Int] = .init(0 ... 10000)

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(batch: ints))
            }
        }
        Benchmark.init(
            "Standard RoundtripStringBatch",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            let strings: [String] = (0 ... 10000).map { String.init($0 * 131989, radix: 16) }

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(batch: strings))
            }
        }
        Benchmark.init(
            "Standard RoundtripDictionary?",
            configuration: .init(metrics: .default, timeUnits: .microseconds)
        ) {
            /// representative of CacheSynchronizationClientEndpoint
            let strings: [String] = (0 ... 100).map { String.init($0 * 131989, radix: 16) }
            let dictionaries: [[Int: [String: Int]]?] = (0 ... 100).map { (_: Int) in
                (0 ... 100).reduce(into: [:]) {
                    let keys: [String] = strings.shuffled()
                    $0[$1] = keys.reduce(into: [:]) {
                        $0[$1] = .random(in: .min ... .max)
                    }
                }
            }
            let frame: UnsafeMutableRawBufferPointer = .allocate(
                byteCount: dictionaries.reduce(0) { max($0, $1.transferSize) },
                alignment: 16
            )
            defer {
                frame.deallocate()
            }

            $0.startMeasurement()

            for _: Int in $0.scaledIterations {
                blackHole(try Self.roundtrip(dictionaries, frame: frame))
            }
        }
    }
}
