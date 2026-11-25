import DistributedABI

/// Collection-heavy: a subscribed object set (`[UInt64]`) plus mixed-case settings.
struct ComputedPropertySubscriptionLike {
    var setIdentifier: UInt64
    var objects: [UInt64]
    var settings: [PropertyLike]
}
extension ComputedPropertySubscriptionLike {
    static func sample(objectCount: Int, _ i: Int) -> Self {
        let objects: [UInt64] = (0 ..< objectCount).map {
            0x3000_0000_0000_0000 &+ UInt64.init($0) &+ UInt64.init(i)
        }
        return .init(
            setIdentifier: 0x4000_0000_0000_0000 &+ UInt64.init(i),
            objects: objects,
            settings: PropertyLike.settings
        )
    }
}
extension ComputedPropertySubscriptionLike: Equatable {}
extension ComputedPropertySubscriptionLike: Transferable {
    var transferSize: Int {
        self.setIdentifier.transferSize
            + self.objects.transferSize
            + self.settings.transferSize
    }

    func transfer(into output: inout TransferWriter) {
        self.setIdentifier.transfer(into: &output)
        self.objects.transfer(into: &output)
        self.settings.transfer(into: &output)
    }
    init(transferring input: inout TransferReader) throws(TransferError) {
        self.init(
            setIdentifier: try .init(transferring: &input),
            objects: try .init(transferring: &input),
            settings: try .init(transferring: &input)
        )
    }
}
