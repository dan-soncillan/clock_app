// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClockApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClockApp", targets: ["ClockApp"]),
        .library(name: "ClockCore", targets: ["ClockCore"])
    ],
    targets: [
        // 時刻計算・フォーマットなど、UI に依存しない純粋なロジック。
        .target(name: "ClockCore"),

        // SwiftUI アプリ本体。
        .executableTarget(
            name: "ClockApp",
            dependencies: ["ClockCore"]
        ),

        .testTarget(
            name: "ClockCoreTests",
            dependencies: ["ClockCore"]
        )
    ]
)
