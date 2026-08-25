// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "battery_plus", path: "../.packages/battery_plus-7.1.1"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus-13.2.0"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-21.0.0"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-5.1.0"),
        .package(name: "light", path: "../.packages/light-5.0.0"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.2.1"),
        .package(name: "pedometer", path: "../.packages/pedometer-4.2.0"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.6.1"),
        .package(name: "screen_state", path: "../.packages/screen_state-5.0.2"),
        .package(name: "sensors_plus", path: "../.packages/sensors_plus-7.1.0"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "battery-plus", package: "battery_plus"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "light", package: "light"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "pedometer", package: "pedometer"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "screen-state", package: "screen_state"),
                .product(name: "sensors-plus", package: "sensors_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
