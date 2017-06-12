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


open class USBDevice: NSObject {
    public let id:UInt64
    public let vendorId:UInt16
    public let productId:UInt16
    public let deviceName:String
    
    public var deviceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
    public var plugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
    public var interfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
    
    public required init(id:UInt64, vendorId:UInt16, productId:UInt16, deviceName:String = "Unnamed USB Device") {
        self.id = id
        self.vendorId = vendorId
        self.productId = productId
        self.deviceName = deviceName
    }
    
}
