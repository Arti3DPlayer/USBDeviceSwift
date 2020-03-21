// swift-tools-version:4.0

//
//  Package.swift
//  
//
//  Created by Artem Hruzd on 6/14/17.
//
//

import PackageDescription

let package = Package(
    name: "USBDeviceSwift",
    products: [
        .library(
            name: "USBDeviceSwift",
            targets: ["USBDeviceSwift"]),
    ],
    targets: [
        .target(
            name: "USBDeviceSwift",
            path: "Sources"),
    ]
)
