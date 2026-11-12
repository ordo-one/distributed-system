extension Handle {
    final class Box: Sendable {
        let value: UInt64

        init(value: UInt64) {
            self.value = value
        }
    }
}
