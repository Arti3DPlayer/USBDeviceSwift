//
//  SerialDevice.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 3/9/18.
//  Copyright © 2018 Artem Hruzd. All rights reserved.
//

import Foundation
import IOKit.serial


public extension Notification.Name {
    static let SerialDeviceAdded = Notification.Name("SerialDeviceAdded")
    static let SerialDeviceRemoved = Notification.Name("SerialDeviceRemoved")
}

public struct SerialDevice {
    public let path:String
    public var name:String? // USB Product Name
    public var vendorName:String? //USB Vendor Name
    public var serialNumber:String? //USB Serial Number
    public var vendorId:Int? //USB Vendor id
    public var productId:Int? //USB Product id
    
    init(path:String) {
        self.path = path
    }
}

extension SerialDevice: Hashable {
    public var hashValue: Int {
        return "\(path)".hashValue
    }
    
    public static func ==(lhs: SerialDevice, rhs: SerialDevice) -> Bool {
        return lhs.path == rhs.path
    }
}
