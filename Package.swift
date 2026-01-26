// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeoSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "NeoSwift",
                 targets: ["NeoSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/leif-ibsen/BigInt", "1.4.0"..<"2.0.0"),
        .package(url: "https://github.com/leif-ibsen/SwiftECC", "5.0.0"..<"6.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", "1.8.0"..<"2.0.0"),
        .package(url: "https://github.com/greymass/swift-scrypt.git", "1.0.0"..<"2.0.0"),
        .package(url: "https://github.com/pengpengliu/BIP39", "1.0.1"..<"2.0.0"),
    ],
    targets: [
        .target(name: "NeoSwift",
                dependencies: ["BigInt", "CryptoSwift", "SwiftECC", "BIP39",
                               .product(name: "Scrypt", package: "swift-scrypt")]),
        .testTarget(name: "NeoSwiftTests",
                    dependencies: ["NeoSwift", "BigInt", "SwiftECC"],
                    resources: [.process("unit/resources/")]),
    ]
)
