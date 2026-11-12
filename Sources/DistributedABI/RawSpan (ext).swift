extension RawSpan {
    /// The offset of the first of these bytes that is `cases` or more, each the stored byte of
    /// a value with that many discriminants, or nil when there is none. The bytes are scanned
    /// once for their largest, which vectorizes, and searched byte by byte only when that is
    /// out of range.
    @inlinable func firstDiscriminant(notBelow cases: Int) -> Int? {
        let bytes: Span<UInt8> = .init(viewing: self)
        var largest: UInt8 = 0
        for i: Int in bytes.indices {
            largest = max(largest, bytes[i])
        }
        guard Int.init(largest) >= cases else {
            return nil
        }
        for i: Int in bytes.indices where Int.init(bytes[i]) >= cases {
            return i
        }
        return nil
    }
}
