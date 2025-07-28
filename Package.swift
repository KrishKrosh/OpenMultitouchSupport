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
            // path: "OpenMultitouchSupportXCF.xcframework"
            url: "https://github.com/KrishKrosh/OpenMultitouchSupport/releases/download/v1.0.8/OpenMultitouchSupportXCF.xcframework.zip",
            checksum: "e3ebaf1248c46dc735cdd32876e93d097b5b645523339109adec75e148124262"
        ),
        .target(
            name: "OpenMultitouchSupport",
            dependencies: ["OpenMultitouchSupportXCF"],
            swiftSettings: swiftSettings
        )
    ]
)
