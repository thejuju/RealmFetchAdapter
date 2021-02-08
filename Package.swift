// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RealmFetchAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "RealmFetchAdapter",
            targets: ["RealmFetchAdapter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ra1028/DifferenceKit.git", .upToNextMajor(from: "1.1.5")),
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", .upToNextMajor(from: "10.5.1")),
    ],
    targets: [
        .target(
            name: "RealmFetchAdapter",
            dependencies: [
                "DifferenceKit",
                .product(name: "Realm", package: "Realm"),
                .product(name: "RealmSwift", package: "Realm"),],
            path: "RealmFetchAdapter/source"
        ),
    ]
    //,swiftLanguageVersions: [.v5]
)
