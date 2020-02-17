// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "ReducerArchitecture",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13),
    ],
    products: [
        .library(
            name: "ReducerArchitecture",
            targets: ["ReducerArchitecture"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ReducerArchitecture",
            dependencies: [])
    ]
)
