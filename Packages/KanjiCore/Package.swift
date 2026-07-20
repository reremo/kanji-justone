// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KanjiCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KanjiCore", targets: ["KanjiCore"]),
    ],
    targets: [
        .target(name: "KanjiCore"),
        .testTarget(name: "KanjiCoreTests", dependencies: ["KanjiCore"]),
    ]
)
