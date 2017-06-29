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
    
    public init (vendorId:Int, productId:Int) {
        self.vendorId = vendorId
        self.productId = productId
    }
}

public struct HIDDevice {
    public let id:String
    public let vendorId:Int
    public let productId:Int
    public let reportSize:Int
    public let device:IOHIDDevice
    public let name:String
    
    public init(device:IOHIDDevice) {
        self.device = device
        
        self.id = IOHIDDeviceGetProperty(self.device, kIOHIDLocationIDKey as CFString) as? String ?? ""
        self.name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? ""
        self.vendorId = IOHIDDeviceGetProperty(self.device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        self.productId = IOHIDDeviceGetProperty(self.device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        self.reportSize = IOHIDDeviceGetProperty(self.device, kIOHIDMaxInputReportSizeKey as CFString) as? Int ?? 0
    }
}
