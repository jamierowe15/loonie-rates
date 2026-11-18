// swift-tools-version: 5.9
import PackageDescription

// RatesKit holds everything that isn't screen code: models, JSON decoding, the API client,
// money maths and the offline cache. It only uses Foundation, so it builds and tests on
// macOS, Linux and Windows, and the app stays thin.
let package = Package(
    name: "RatesKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "RatesKit", targets: ["RatesKit"])],
    targets: [
        .target(name: "RatesKit"),
        .testTarget(name: "RatesKitTests", dependencies: ["RatesKit"]),
    ]
)
