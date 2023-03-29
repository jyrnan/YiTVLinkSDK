// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YiTVLinkSDK",
    platforms: [ // 本 Package 适用的平台
        .iOS(.v14)
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "YiTVLinkSDK",
            targets: ["YiTVLinkSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
         .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "YiTVLinkSDK",
            dependencies: [.product(name: "Vapor", package: "vapor"),
                           .product(name: "Leaf", package: "leaf")],
            swiftSettings: [.define("TEST", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "YiTVLinkSDKTests",
            dependencies: ["YiTVLinkSDK"]),
        
                
            
    ]
)
