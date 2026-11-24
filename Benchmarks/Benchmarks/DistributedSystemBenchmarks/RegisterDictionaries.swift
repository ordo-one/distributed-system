import Benchmark
import DistributedABI

/// The two halves of `Standard RoundtripDictionary?`, measured apart, over values of the same
/// shape: the read builds a dictionary of strings for every entry, which is most of the round
/// trip and hides any change to the write. The write sizes each value from `transferSize` and
/// writes it into one frame, reserved before the measurement for the largest value, as a send
/// does and as the round trip does; the read decodes each value from bytes written before the
/// measurement, and keeps the values until the last, as the round trip does. The contents are
/// the same in every run, but the order of each dictionary’s entries, in memory and on the
/// wire, still follows the hash seed of the process. Both rows are `Standard`, as the round
/// trip is: the dictionary is a standard type.
func RegisterDictionaries() {
    let configuration: Benchmark.Configuration = .init(
        metrics: .default,
        timeUnits: .microseconds
    )

    Benchmark.init(
        "Standard WriteDictionary?",
        configuration: configuration
    ) { (benchmark: Benchmark, fixture: (values: [[Int: [String: Int]]?], capacity: Int)) in
        let frame: UnsafeMutableRawBufferPointer = .allocate(
            byteCount: fixture.capacity,
            alignment: 16
        )
        defer {
            frame.deallocate()
        }
        benchmark.startMeasurement()
        for _: Int in benchmark.scaledIterations {
            for dictionary: [Int: [String: Int]]? in fixture.values {
                blackHole(Sends.send(dictionary, into: frame))
            }
        }
    } setup: {
        let values: [[Int: [String: Int]]?] = Dictionaries.values()
        return (values, values.reduce(0) { max($0, $1.transferSize) })
    }
    Benchmark.init(
        "Standard ReadDictionary?",
        configuration: configuration
    ) { (benchmark: Benchmark, frames: [[UInt8]]) in
        benchmark.startMeasurement()
        for _: Int in benchmark.scaledIterations {
            blackHole(try Dictionaries.read(frames, as: [Int: [String: Int]]?.self))
        }
    } setup: {
        Dictionaries.values().map { [UInt8].init(transferring: $0) }
    }
}
