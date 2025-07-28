// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "OpenMultitouchSupport",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "OpenMultitouchSupport",
            targets: ["OpenMultitouchSupport"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "OpenMultitouchSupportXCF",
            url: "https://github.com/KrishKrosh/OpenMultitouchSupport/releases/download/v1.0.6/OpenMultitouchSupportXCF.xcframework.zip",
            checksum: "175cb56a24ae0d085d7869aae332dd28bd43de5fe5a048f0f888a62c2a4f86c5",
            path: "OpenMultitouchSupportXCF.xcframework"
        ),
        .target(
            name: "OpenMultitouchSupport",
            dependencies: ["OpenMultitouchSupportXCF"],
            swiftSettings: swiftSettings
        )
    ]
)
