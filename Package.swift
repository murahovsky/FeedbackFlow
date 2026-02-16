// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FeedbackFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeedbackFlow",
            targets: ["FeedbackFlow"]
        ),
    ],
    targets: [
        .target(
            name: "FeedbackFlow"
        ),
    ]
)
