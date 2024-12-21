// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SQLiteValidator",
    platforms: [.macOS(.v10_15), .iOS(.v12), .tvOS(.v12), .watchOS(.v4), .macCatalyst(.v13)],
    products: [
        .library(name: "SQLiteValidator", targets: ["SQLiteValidator"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.55.0"),
    ],
    targets: [
        .macro(
            name: "SQLiteValidatorMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),

        .target(name: "SQLiteValidator", dependencies: ["SQLiteValidatorMacros"]),

        .testTarget(
            name: "SQLiteValidatorTests",
            dependencies: [
                "SQLiteValidatorMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
