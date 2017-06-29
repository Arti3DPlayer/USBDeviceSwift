//
//  USBDevice.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 6/11/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

//from IOUSBLib.h
public let kIOUSBDeviceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0x9d, 0xc7, 0xb7, 0x80, 0x9e, 0xc0, 0x11, 0xD4,
                                                                  0xa5, 0x4f, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
public let kIOUSBDeviceInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                             0x5c, 0x81, 0x87, 0xd0, 0x9e, 0xf3, 0x11, 0xD4,
                                                             0x8b, 0x45, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)

//from IOCFPlugin.h
public let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
                                                            0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F)


/*!
 @defined USBmakebmRequestType
 @discussion Macro to encode the bRequest field of a Device Request.  It is used when constructing an IOUSBDevRequest.
 */

public func USBmakebmRequestType(direction:Int, type:Int, recipient:Int) -> UInt8 {
    return UInt8((direction & kUSBRqDirnMask) << kUSBRqDirnShift)|UInt8((type & kUSBRqTypeMask) << kUSBRqTypeShift)|UInt8(recipient & kUSBRqRecipientMask)
}

public extension Notification.Name {
    static let USBDeviceConnected = Notification.Name("USBDeviceConnected")
    static let USBDeviceDisconnected = Notification.Name("USBDeviceDisconnected")
}

public struct USBMonitorData {
    public let vendorId:UInt16
    public let productId:UInt16
    
    public init (vendorId:UInt16, productId:UInt16) {
        self.vendorId = vendorId
        self.productId = productId
    }
}

public struct USBDevice {
    public let id:UInt64
    public let vendorId:UInt16
    public let productId:UInt16
    public let name:String
    
    public let deviceInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
    public let plugInInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
    
    public init(id:UInt64,
                vendorId:UInt16,
                productId:UInt16,
                name:String,
                deviceInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?,
                plugInInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?) {
        self.id = id
        self.vendorId = vendorId
        self.productId = productId
        self.name = name
        self.deviceInterfacePtrPtr = deviceInterfacePtrPtr
        self.plugInInterfacePtrPtr = plugInInterfacePtrPtr
    }
}
