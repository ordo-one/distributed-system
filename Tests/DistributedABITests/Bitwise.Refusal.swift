extension Bitwise {
    /// A refusal, and where it left the reader.
    struct Refusal: Equatable {
        let kind: HostileInput.Expectation
        let remaining: Int

        init(kind: HostileInput.Expectation, remaining: Int) {
            self.kind = kind
            self.remaining = remaining
        }
    }
}
