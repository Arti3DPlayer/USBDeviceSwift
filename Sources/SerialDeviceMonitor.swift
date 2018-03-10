//
//  SerialDeviceMonitor.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 3/9/18.
//  Copyright © 2018 Artem Hruzd. All rights reserved.
//

import Cocoa
import Foundation
import IOKit
import IOKit.serial


open class SerialDeviceMonitor {
    var serialDevices:[SerialDevice] = []
    var portUsageIntervalTime:Float = 0.25
    open var filterDevices:((_ devices:[SerialDevice])->[SerialDevice])?
    
    public init() {
    }
    
    private func getParentProperty(device:io_object_t, key:String) -> AnyObject? {
        return IORegistryEntrySearchCFProperty(device, kIOServicePlane, key as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
    }
    
    func getDeviceProperty(device:io_object_t, key:String) -> AnyObject? {
        let cfKey = key as CFString
        let propValue = IORegistryEntryCreateCFProperty(device, cfKey, kCFAllocatorDefault, 0)
        
        return propValue?.takeUnretainedValue()
    }
    
    func getSerialDevices(iterator: io_iterator_t) {
        var newSerialDevices:[SerialDevice] = []
        while case let serialPort = IOIteratorNext(iterator), serialPort != 0 {
            guard let calloutDevice = getDeviceProperty(device: serialPort, key: kIOCalloutDeviceKey) as? String else {
                continue
            }
            
            var sd = SerialDevice(path: calloutDevice)
            sd.name = getParentProperty(device: serialPort, key: "USB Product Name") as? String
            sd.vendorName = getParentProperty(device: serialPort, key: "USB Vendor Name") as? String
            sd.serialNumber = getParentProperty(device: serialPort, key: "USB Serial Number") as? String
            sd.vendorId = getParentProperty(device: serialPort, key: "idVendor") as? Int
            sd.productId = getParentProperty(device: serialPort, key: "idProduct") as? Int

            newSerialDevices.append(sd)
            IOObjectRelease(serialPort)
        }
        IOObjectRelease(iterator)
        
        if (filterDevices != nil) {
            newSerialDevices = filterDevices!(newSerialDevices)
        }
        
        let oldSet = Set(serialDevices)
        let newSet = Set(newSerialDevices)
        
        
        
        for sd in oldSet.subtracting(newSet) {
            NotificationCenter.default.post(name: .SerialDeviceRemoved, object: ["device": sd])
        }
        
        for sd in newSet.subtracting(oldSet) {
            NotificationCenter.default.post(name: .SerialDeviceAdded, object: ["device": sd])
        }
        
        serialDevices = newSerialDevices
    }
    
    @objc open func start() {
        while true {
            var portIterator: io_iterator_t = 0
            var result: kern_return_t = KERN_FAILURE
            let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
            classesToMatch[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes
            result = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &portIterator)
            if result == KERN_SUCCESS {
                getSerialDevices(iterator: portIterator)
            }
            usleep(UInt32(portUsageIntervalTime*1000000))
        }
    }
}
