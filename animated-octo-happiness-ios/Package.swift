// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "animated-octo-happiness-ios",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "animated-octo-happiness-ios",
            targets: ["animated-octo-happiness-ios"]),
    ],
    dependencies: [
        // Firebase iOS SDK
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.0.0"
        )
    ],
    targets: [
        .target(
            name: "animated-octo-happiness-ios",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "animated-octo-happiness-ios",
            exclude: [
                "Info.plist",
                "GoogleService-Info.plist",
                "GoogleService-Info-Template.plist"
            ]
        ),
        .testTarget(
            name: "animated-octo-happiness-iosTests",
            dependencies: ["animated-octo-happiness-ios"],
            path: "animated-octo-happiness-iosTests"
        )
    ]
)