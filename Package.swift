// swift-tools-version: 6.3
import PackageDescription

let package: Package = .init(
    name: "distributed-system",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "OrdoDistributedABI",
            type: .dynamic,
            targets: ["DistributedABI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/dollup", from: "1.3.4"),
    ],
    targets: [
        .target(
            name: "DistributedABI",
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes"),
                .strictMemorySafety(),
                .unsafeFlags(["-enable-library-evolution", "-emit-module-interface"]),
            ]
        ),
        .testTarget(
            name: "DistributedABITests",
            dependencies: [
                .target(name: "DistributedABI"),
            ]
        ),
    ]
)

for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.treatWarning("ExistentialAny", as: .error))
        settings.append(.treatWarning("MutableGlobalVariable", as: .error))

        $0 = settings
    } (&target.swiftSettings)
}
