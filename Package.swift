// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RestApp",
    platforms: [
        .macOS(.v13) // Upgrade to macOS Ventura (13.0) for Swift Charts
    ],
    products: [
        // 定义生成的可执行程序名称
        .executable(name: "MinTik", targets: ["RestApp"])
    ],
    targets: [
        // 源代码目标，SPM 会自动去 Sources/RestApp 目录下寻找代码
        .executableTarget(
            name: "RestApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)