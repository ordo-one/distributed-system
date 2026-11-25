import Benchmark
import DistributedABI

/// The measured bodies of the rows that ``Strings.register()`` registers.
enum Strings {}
extension Strings {
    @inline(never) static func write<Value>(
        _ values: [Value],
        into frame: UnsafeMutableRawBufferPointer
    ) -> Int where Value: Transferable {
        //  no check of the room left before each value, as a container makes none: the output
        //  traps if the frame is too small
        var output: OutputRawSpan = .init(buffer: frame, initializedCount: 0)
        output.withTransferWriter {
            for value: Value in values {
                value.transfer(into: &$0)
            }
        }
        return output.finalize(for: frame)
    }

    /// The size pass alone.
    @inline(never) static func size<Value>(_ value: Value) -> Int where Value: Transferable {
        value.transferSize
    }

    /// The write pass alone, into a frame the caller sized for the value before the
    /// measurement.
    @inline(never) static func write<Value>(
        sized value: Value,
        into frame: UnsafeMutableRawBufferPointer
    ) -> Int where Value: Transferable {
        var output: OutputRawSpan = .init(buffer: frame, initializedCount: 0)
        output.withTransferWriter { value.transfer(into: &$0) }
        return output.finalize(for: frame)
    }

    /// The read pass alone, from a frame the write pass filled.
    @inline(never) static func read<Value>(
        _: Value.Type,
        from frame: UnsafeMutableRawBufferPointer,
        count: Int
    ) throws(TransferError) -> Value where Value: Transferable {
        var input: TransferReader = .init(
            unsafe UnsafeRawBufferPointer.init(rebasing: frame[..<count]).bytes
        )
        let value: Value = try .init(transferring: &input)
        try input.readEnd()
        return value
    }

    /// Writes `values` once as the row does, so we KNOW it fills exactly the frame it reserves
    /// with bytes that read back as the same strings, one after another, before measuring.
    static func writes<Value>(
        _ values: [Value],
        exactly capacity: Int
    ) -> Bool where Value: Transferable & Equatable {
        var bytes: [UInt8] = .init(repeating: 0, count: capacity)
        let count: Int = bytes.withUnsafeMutableBytes { Self.write(values, into: $0) }
        guard count == capacity else {
            return false
        }
        do {
            var input: TransferReader = .init(bytes.span.bytes)
            for value: Value in values {
                guard try Value.init(transferring: &input) == value else {
                    return false
                }
            }
            try input.readEnd()
            return true
        } catch {
            return false
        }
    }
}
extension Strings {
    /// A string write on its own, as the transport makes one for every string argument, element
    /// or field: the length, then the bytes, both written by `transfer(into:)`, into a frame
    /// the caller reserved. The round trips measure the write together with the read and the
    /// allocation of the decoded string. Every row here is `Standard`: a string is a standard
    /// type.
    static func register() {
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
                blackHole(Self.size(batch))
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
                blackHole(Self.write(sized: batch, into: frame))
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
                blackHole(try Self.read([String].self, from: frame, count: count))
            }
        }

        func register<Value>(
            _ name: String,
            _ values: [Value]
        ) where Value: Transferable & Equatable {
            let capacity: Int = values.reduce(0) { $0 + $1.transferSize }
            precondition(Self.writes(values, exactly: capacity), "\(name) write mismatch")
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
                    blackHole(Self.write(values, into: frame))
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
}
