// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SafeInject",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    products: [
        .library(name: "SafeInject", targets: ["SafeInject"]),
        .library(name: "SafeInjectTesting", targets: ["SafeInjectTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0"..<"601.0.0"),
    ],
    targets: [
        .macro(
            name: "SafeInjectMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "SafeInject",
            dependencies: ["SafeInjectMacros"]
        ),
        .target(
            name: "SafeInjectTesting",
            dependencies: ["SafeInject"]
        ),
        .testTarget(
            name: "SafeInjectTests",
            dependencies: [
                "SafeInject",
                "SafeInjectTesting",
                "SafeInjectMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
