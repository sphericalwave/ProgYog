// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GenerateIcons",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../../../../Frameworks/Tools/brand-asset-gen"),
    ],
    targets: [
        .executableTarget(
            name: "GenerateIcons",
            dependencies: [
                .product(name: "BrandGenCore", package: "brand-asset-gen"),
            ]
        ),
    ]
)
