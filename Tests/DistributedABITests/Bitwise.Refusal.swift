extension Bitwise {
    /// A refusal, and where it left the reader.
    struct Refusal: Equatable {
        let kind: HostileInput.Expectation
        let remaining: Int
    }
}
