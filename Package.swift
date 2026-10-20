// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirKeyboardCore",
    platforms: [.macOS(.v13), .iOS("18.0")],
    products: [.library(name: "AirKeyboardCore", targets: ["AirKeyboardCore"])],
    targets: [
        .target(name: "AirKeyboardCore", path: "Shared/Core"),
        .testTarget(name: "AirKeyboardCoreTests", dependencies: ["AirKeyboardCore"], path: "Tests/CoreTests")
    ]
)
