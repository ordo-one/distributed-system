import Benchmark
import DistributedABI

func RegisterRoundtrips() {
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
            blackHole(try Roundtrips.roundtrip(ints, frame: frame))
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
            blackHole(try Roundtrips.roundtrip(ints, frame: frame))
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
            blackHole(try Roundtrips.roundtrip(strings, frame: frame))
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
            blackHole(try Roundtrips.roundtrip(strings, frame: frame))
        }
    }
    Benchmark.init(
        "Standard RoundtripIntBatch",
        configuration: .init(metrics: .default, timeUnits: .microseconds)
    ) {
        let ints: [Int] = .init(0 ... 10000)

        $0.startMeasurement()

        for _: Int in $0.scaledIterations {
            blackHole(try Roundtrips.roundtrip(batch: ints))
        }
    }
    Benchmark.init(
        "Standard RoundtripStringBatch",
        configuration: .init(metrics: .default, timeUnits: .microseconds)
    ) {
        let strings: [String] = (0 ... 10000).map { String.init($0 * 131989, radix: 16) }

        $0.startMeasurement()

        for _: Int in $0.scaledIterations {
            blackHole(try Roundtrips.roundtrip(batch: strings))
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
            blackHole(try Roundtrips.roundtrip(dictionaries, frame: frame))
        }
    }
}
