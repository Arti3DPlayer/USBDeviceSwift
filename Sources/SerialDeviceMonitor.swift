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
    
    public init() {
    }
    
    private func getParentProperty(device:io_object_t, key:String) -> AnyObject? {
        return IORegistryEntrySearchCFProperty(device, kIOServicePlane, key as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
    }
    
    func getDeviceClass(device:io_object_t) -> String {
        var nameCString:[CChar] = [CChar](repeating: 0, count: 128)
        let kern_result = IOObjectGetClass(device, &nameCString)
        
        if kern_result == KERN_SUCCESS {
            return String(cString: nameCString)
        }
        
        return ""
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
            print("\(kIOCalloutDeviceKey): \(calloutDevice)")
            
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
        
        print(newSerialDevices)
    }
    
    @objc open func start() {
        //while true {
            var portIterator: io_iterator_t = 0
            var result: kern_return_t = KERN_FAILURE
            let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
            classesToMatch[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes
            result = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &portIterator)
            if result == KERN_SUCCESS {
                getSerialDevices(iterator: portIterator)
            }
            usleep(1000000)
        //}
    }
}
