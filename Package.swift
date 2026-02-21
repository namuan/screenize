// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Screenize",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Screenize", targets: ["Screenize"])
    ],
    targets: [
        .executableTarget(
            name: "Screenize",
            path: "Screenize",
            exclude: [
                "Info.plist",
                "Screenize.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
