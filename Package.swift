// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FinderColorTagger",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FinderColorTagger", targets: ["FinderColorTagger"])
    ],
    targets: [
        .executableTarget(name: "FinderColorTagger")
    ]
)
