extension Identifier {
    /// The byte count of an identifier handed anything other than 8 bytes.
    struct ByteCount: Error {
        let count: Int
    }
}
