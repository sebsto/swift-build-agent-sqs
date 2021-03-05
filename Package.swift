// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BuildAgentSQS",
    products: [
        .executable(name: "SQSBuildAgent", targets: ["SQSBuildAgent"]),
        .executable(name: "SQSProducer", targets: ["SQSProducer"]),
        .library(name: "SQSAgentLib", targets: ["SQSAgentLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/soto-project/soto", from: "5.0.0")
//        .package(path: "~/Documents/code/swift/soto")
    ],
    targets: [
        .target(name: "SQSBuildAgent", dependencies: [
            "SQSAgentLib",
        ]),
        .target(name: "SQSProducer", dependencies: [
            "SQSAgentLib",
        ]),
        .target(name: "SQSAgentLib", dependencies: [
            .product(name: "SotoSQS", package: "soto")
        ])
    ]
)
