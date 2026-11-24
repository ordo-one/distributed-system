import Benchmark
import DistributedABI

/// A string write on its own, as the transport makes one for every string argument, element
/// or field: the length, then the bytes, both written by `transfer(into:)`, into a frame the
/// caller reserved. The round trips measure the write together with the read and the
/// allocation of the decoded string. Every row here is `Standard`: a string is a standard type.
func RegisterStrings() {
    let configuration: Benchmark.Configuration = .init(
        metrics: .default,
        timeUnits: .microseconds
    )

    //  The batch of 10,001 short strings as one array, as `Standard RoundtripStringBatch`
    //  sends it, one phase at a time: the size pass, the write pass into a frame sized for
    //  it, and the read pass from that frame.
    let batch: [String] = (0 ... 10000).map { String.init($0 * 131989, radix: 16) }
    Benchmark.init(
        "Standard SizeStringBatch",
        configuration: configuration
    ) { (benchmark: Benchmark) in
        for _: Int in benchmark.scaledIterations {
            blackHole(Strings.size(batch))
        }
    }
    Benchmark.init(
        "Standard WriteStringBatch",
        configuration: configuration
    ) { (benchmark: Benchmark) in
        let frame: UnsafeMutableRawBufferPointer = .allocate(
            byteCount: batch.transferSize,
            alignment: 16
        )
        defer {
            frame.deallocate()
        }
        benchmark.startMeasurement()
        for _: Int in benchmark.scaledIterations {
            blackHole(Strings.write(sized: batch, into: frame))
        }
    }
    Benchmark.init(
        "Standard ReadStringBatch",
        configuration: configuration
    ) { (benchmark: Benchmark) in
        let frame: UnsafeMutableRawBufferPointer = .allocate(
            byteCount: batch.transferSize,
            alignment: 16
        )
        defer {
            frame.deallocate()
        }
        let count: Int = Sends.send(batch, into: frame)
        benchmark.startMeasurement()
        for _: Int in benchmark.scaledIterations {
            blackHole(try Strings.read([String].self, from: frame, count: count))
        }
    }

    func register<Value>(
        _ name: String,
        _ values: [Value]
    ) where Value: Transferable & Equatable {
        let capacity: Int = values.reduce(0) { $0 + $1.transferSize }
        precondition(Strings.writes(values, exactly: capacity), "\(name) write mismatch")
        Benchmark.init(name, configuration: configuration) { (benchmark: Benchmark) in
            let frame: UnsafeMutableRawBufferPointer = .allocate(
                byteCount: max(capacity, 1),
                alignment: 16
            )
            defer {
                frame.deallocate()
            }
            benchmark.startMeasurement()
            for _: Int in benchmark.scaledIterations {
                blackHole(Strings.write(values, into: frame))
            }
        }
    }

    //  one to eight bytes each, stored inline in the string
    register(
        "Standard WriteString",
        (0 ... 10000).map { String.init($0 * 131989, radix: 16) }
    )
    //  native strings in a heap allocation of their own
    register(
        "Standard WriteString 32 bytes",
        (0 ... 10000).map {
            let digits: String = .init($0 * 131989, radix: 16)
            return String.init(repeating: "x", count: 32 - digits.count) + digits
        }
    )

    #if _runtime(_ObjC)
    //  The last character of a string bridged from an `NSString` with UTF-16 contents: the
    //  write costs the same however much text precedes the substring.
    for backing: Int in [10_000, 1_000_000] {
        let string: String = .bridged(count: backing)
        precondition(!string.isContiguousUTF8, "the string must stay bridged")
        register("Standard WriteBridgedSuffix \(backing)", [string.suffix(1)])
    }
    #endif
}
