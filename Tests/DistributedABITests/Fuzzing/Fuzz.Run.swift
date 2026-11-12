import SystemIO

extension Fuzz {
    /// The iterations and the seed of one fuzz test of one type.
    struct Run: ~Copyable {
        let iterations: UInt64
        let seed: UInt64
        let type: String
        /// In a long run, the file that names the iteration in progress.
        let progress: FileDescriptor?

        init(
            iterations: UInt64,
            seed: UInt64,
            type: String,
            progress: FileDescriptor?
        ) {
            self.iterations = iterations
            self.seed = seed
            self.type = type
            self.progress = progress
        }
    }
}
extension Fuzz.Run {
    private static var iterationsVariable: String { "DISTRIBUTED_ABI_FUZZ_ITERATIONS" }
    private static var seedVariable: String { "DISTRIBUTED_ABI_FUZZ_SEED" }

    /// Runs `body` for a few thousand iterations from a fixed seed, unless the environment
    /// asks for more, in which case the seed is random unless the environment gives one too.
    /// A long run prints its seed first, and keeps the iteration in progress in a file it
    /// names, so that a trap, which ends the process before the test can report it, can be
    /// replayed as well as a failure.
    static func perform<Value>(
        _: Value.Type,
        test: String,
        with body: (borrowing Self) throws -> Void
    ) throws {
        let iterations: UInt64? = try Self.iterations()
        let seed: UInt64? = try Self.seed()
        let type: String = "\(Value.self)"
        if  let iterations: UInt64 {
            let seed: UInt64 = seed ?? .random(in: .min ... .max)
            let path: FilePath = try Self.progressPath(test: test, type: type)
            print(
                """
                fuzzing \(type) \(iterations) times from seed \(Self.hex(seed)), \
                the iteration in progress in \(path)
                """
            )
            try path.open(
                .writeOnly,
                permissions: (.rw, .rw, .r),
                options: [.create, .truncate]
            ) { (file: FileDescriptor) in
                let run: Self = .init(
                    iterations: iterations,
                    seed: seed,
                    type: type,
                    progress: file
                )
                try body(run)
            }
            try path.remove()
        } else {
            let run: Self = .init(
                iterations: 2_000,
                seed: seed ?? 0x0123_4567_89ab_cdef,
                type: type,
                progress: nil
            )
            try body(run)
        }
    }

    private static func iterations() throws -> UInt64? {
        do throws(Environment.VariableGetterError<UInt64>) {
            return try Environment[Self.iterationsVariable]
        } catch .undefined {
            return nil
        }
    }

    private static func seed() throws -> UInt64? {
        guard
        let value: String = Environment[Self.seedVariable] else {
            return nil
        }
        let parsed: UInt64?
        if  let digits: String.Index = value.index(
                value.startIndex,
                offsetBy: 2,
                limitedBy: value.endIndex
            ),
            value[..<digits] == "0x" {
            parsed = .init(value[digits...], radix: 16)
        } else {
            parsed = .init(value)
        }
        guard
        let seed: UInt64 = parsed else {
            throw Environment.VariableGetterError<UInt64>.malformed(
                Self.seedVariable,
                value: value
            )
        }
        return seed
    }

    /// A path named for the test and the type in a directory of the temporary directory.
    private static func progressPath(test: String, type: String) throws -> FilePath {
        let temporary: FilePath.Directory = (try? Environment["TMPDIR"]) ?? "/tmp"
        let directory: FilePath.Directory = temporary / "distributed-abi-fuzz"
        try directory.create()
        let name: String = .init(
            "\(test) \(type)".map { $0.isASCII && ($0.isLetter || $0.isNumber) ? $0 : "_" }
        )
        return directory / "\(name).txt"
    }
}
extension Fuzz.Run {
    /// The seed of iteration `i`, which replays it as the only iteration of a run.
    func seed(_ i: UInt64) -> UInt64 { self.seed &+ i }

    /// Records, in a long run, that iteration `i` begins. The record never gets shorter, as
    /// the seeds have all their digits and the iterations count up, so writing it over the
    /// last one leaves nothing of that behind.
    func start(_ i: UInt64) throws {
        guard
        let progress: FileDescriptor = self.progress else {
            return
        }
        _ = try progress.seek(offset: 0, from: .start)
        _ = try progress.writeAll("\(self.failure(i))\n".utf8)
    }

    /// The start of a failure message: the type, the iteration, and the seed that replays it.
    func failure(_ i: UInt64) -> String {
        """
        \(self.type), iteration \(i) from seed \(Self.hex(self.seed)) (replay with \
        \(Self.seedVariable)=\(Self.hex(self.seed(i))) \(Self.iterationsVariable)=1)
        """
    }

    /// The seed in hexadecimal with all its digits.
    private static func hex(_ seed: UInt64) -> String {
        let digits: String = .init(seed, radix: 16)
        return "0x\(String.init(repeating: "0", count: 16 - digits.count))\(digits)"
    }
}
