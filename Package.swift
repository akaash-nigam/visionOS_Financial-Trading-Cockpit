// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Financial-Trading-Cockpit",
    platforms: [
        .visionOS(.v1)
    ],
    products: [
        .executable(
            name: "Financial-Trading-Cockpit",
            targets: ["Financial-Trading-Cockpit"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "Financial-Trading-Cockpit",
            path: "TradingCockpit"
        )
    ]
)
