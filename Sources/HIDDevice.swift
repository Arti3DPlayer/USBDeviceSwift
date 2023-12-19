//
//  HIDDevice.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 6/14/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import Foundation
import IOKit.hid

public extension Notification.Name {
    static let HIDDeviceDataReceived = Notification.Name("HIDDeviceDataReceived")
    static let HIDDeviceConnected = Notification.Name("HIDDeviceConnected")
    static let HIDDeviceDisconnected = Notification.Name("HIDDeviceDisconnected")
}

public struct HIDMonitorData {
    public let vendorId:Int
    public let productId:Int
    public var usagePage:Int?
    public var usage:Int?

    public init (vendorId:Int, productId:Int) {
        self.vendorId = vendorId
        self.productId = productId
    }

    public init (vendorId:Int, productId:Int, usagePage:Int?, usage:Int?) {
        self.vendorId = vendorId
        self.productId = productId
        self.usagePage = usagePage
        self.usage = usage
    }
}

public struct HIDDevice: Hashable, Identifiable {

    /// The underlying HID device.
    public let device: IOHIDDevice

    /// The report size.
    public let reportSize: Int

    /// The location ID of the device
    public let id: Int32

    /// The vendor ID.
    public let vendorId: Int16

    /// The product ID.
    public let productId: Int16

    /// The product name.
    public let name: String

    /// The manufacturer of the device.
    public let manufacturer: String

    /// The serial number of the device.
    public let serialNumber: String

    /// The version of the device.
    public let version: Int

    public init(device:IOHIDDevice) {
        self.device = device

        self.id = IOHIDDeviceGetProperty(self.device, kIOHIDLocationIDKey as CFString) as? Int32 ?? 0
        self.name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        self.vendorId = IOHIDDeviceGetProperty(self.device, kIOHIDVendorIDKey as CFString) as? Int16 ?? 0
        self.productId = IOHIDDeviceGetProperty(self.device, kIOHIDProductIDKey as CFString) as? Int16 ?? 0
        self.reportSize = IOHIDDeviceGetProperty(self.device, kIOHIDMaxInputReportSizeKey as CFString) as? Int ?? 0

        self.manufacturer = IOHIDDeviceGetProperty(self.device, kIOHIDManufacturerKey as CFString) as? String ?? ""
        self.serialNumber = IOHIDDeviceGetProperty(self.device, kIOHIDSerialNumberKey as CFString) as? String ?? ""
        self.version = IOHIDDeviceGetProperty(self.device, kIOHIDVersionNumberKey as CFString) as? Int ?? 0

    }
}
