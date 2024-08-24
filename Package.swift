// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SQLiteValidator",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SQLiteValidator",
            targets: ["SQLiteValidator"]
        ),
        .executable(
            name: "SQLiteValidatorClient",
            targets: ["SQLiteValidatorClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
        .package(url: "https://github.com/stackotter/swift-macro-toolkit", from: "0.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "SQLiteValidatorMacros",
            dependencies: [
                .product(name: "MacroToolkit", package: "swift-macro-toolkit"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "SQLiteValidator", dependencies: ["SQLiteValidatorMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "SQLiteValidatorClient", dependencies: ["SQLiteValidator"]),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "SQLiteValidatorTests",
            dependencies: [
                "SQLiteValidatorMacros",
                .product(name: "MacroToolkit", package: "swift-macro-toolkit"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
