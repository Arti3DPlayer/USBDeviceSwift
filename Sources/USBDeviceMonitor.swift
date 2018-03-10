//
//  USBDeviceMonitor.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 6/12/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa


open class USBDeviceMonitor {
    public let vp:[USBMonitorData]

    public init(_ vp:[USBMonitorData]) {
        self.vp = vp
    }
        
    @objc open func start() {
        for vp in self.vp {
            var matchedIterator:io_iterator_t = 0
            var removalIterator:io_iterator_t = 0
            let notifyPort:IONotificationPortRef = IONotificationPortCreate(kIOMasterPortDefault)
            IONotificationPortSetDispatchQueue(notifyPort, DispatchQueue(label: "IODetector"))
            let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
                as NSMutableDictionary
            matchingDict[kUSBVendorID] = NSNumber(value: vp.vendorId)
            matchingDict[kUSBProductID] = NSNumber(value: vp.productId)

            let matchingCallback:IOServiceMatchingCallback = { (userData, iterator) in
                // Convert self to a void pointer, store that in the context, and convert it
                let this = Unmanaged<USBDeviceMonitor>.fromOpaque(userData!).takeUnretainedValue()
                this.rawDeviceAdded(iterator: iterator)
            }
            
            let removalCallback: IOServiceMatchingCallback = {
                (userData, iterator) in
                let this = Unmanaged<USBDeviceMonitor>.fromOpaque(userData!).takeUnretainedValue()
                this.rawDeviceRemoved(iterator: iterator)
            }
            
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            
            IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matchingDict, matchingCallback, selfPtr, &matchedIterator)
            IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchingDict, removalCallback, selfPtr, &removalIterator)
            
            self.rawDeviceAdded(iterator: matchedIterator)
            self.rawDeviceRemoved(iterator: removalIterator)

        }
        
        RunLoop.current.run()
    }

    open func rawDeviceAdded(iterator: io_iterator_t) {
        
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            var score:Int32 = 0
            var kr:Int32 = 0
            var did:UInt64 = 0
            var vid:UInt16 = 0
            var pid:UInt16 = 0

            var deviceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
            var plugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?

            kr = IORegistryEntryGetRegistryEntryID(usbDevice, &did)
            
            if(kr != kIOReturnSuccess) {
                print("Error getting device id")
            }
            
            // io_name_t imports to swift as a tuple (Int8, ..., Int8) 128 ints
            // although in device_types.h it's defined:
            // typedef	char io_name_t[128];
            var deviceNameCString:[CChar] = [CChar](repeating: 0, count: 128)
            kr = IORegistryEntryGetName(usbDevice, &deviceNameCString)
            
            if(kr != kIOReturnSuccess) {
                print("Error getting device name")
            }
            
            let name = String.init(cString: &deviceNameCString)
            
            // Get plugInInterface for current USB device
            kr = IOCreatePlugInInterfaceForService(
                usbDevice,
                kIOUSBDeviceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterfacePtrPtr,
                &score)
            
            // USB device object is no longer needed.
            IOObjectRelease(usbDevice)
            
            // Dereference pointer for the plug-in interface
            if (kr != kIOReturnSuccess) {
                continue
            }
            
            guard let plugInInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
                print("Unable to get Plug-In Interface")
                continue
            }
            
            // use plug in interface to get a device interface
            kr = withUnsafeMutablePointer(to: &deviceInterfacePtrPtr) {
                $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                    plugInInterface.QueryInterface(
                        plugInInterfacePtrPtr,
                        CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                        $0)
                }
            }
            
            // dereference pointer for the device interface
            if (kr != kIOReturnSuccess) {
                continue
            }

            guard let deviceInterface = deviceInterfacePtrPtr?.pointee?.pointee else {
                print("Unable to get Device Interface")
                continue
            }
            
            kr = deviceInterface.USBDeviceOpen(deviceInterfacePtrPtr)
            
            // kIOReturnExclusiveAccess is not a problem as we can still do some things
            if (kr != kIOReturnSuccess && kr != kIOReturnExclusiveAccess) {
                print("Could not open device (error: \(kr))")
                continue
            }
            
            kr = deviceInterface.GetDeviceVendor(deviceInterfacePtrPtr, &vid)
            if (kr != kIOReturnSuccess) {
                continue
            }
            
            kr = deviceInterface.GetDeviceProduct(deviceInterfacePtrPtr, &pid)
            if (kr != kIOReturnSuccess) {
                continue
            }
            
            let device = USBDevice(
                id: did,
                vendorId: vid,
                productId: pid,
                name:name,
                deviceInterfacePtrPtr:deviceInterfacePtrPtr,
                plugInInterfacePtrPtr:plugInInterfacePtrPtr
            )
            
            NotificationCenter.default.post(name: .USBDeviceConnected, object: [
                "device": device
            ])
        }
    }
    
    open func rawDeviceRemoved(iterator: io_iterator_t) {
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            var kr:Int32 = 0
            var did:UInt64 = 0
            
            kr = IORegistryEntryGetRegistryEntryID(usbDevice, &did)
            
            if(kr != kIOReturnSuccess) {
                print("Error getting device id")
            }
            
            // USB device object is no longer needed.
            kr = IOObjectRelease(usbDevice)
            
            if (kr != kIOReturnSuccess)
            {
                print("Couldn’t release raw device object (error: \(kr))")
                continue
            }
            
            NotificationCenter.default.post(name: .USBDeviceDisconnected, object: [
                "id": did
            ])
        }
    }
}

