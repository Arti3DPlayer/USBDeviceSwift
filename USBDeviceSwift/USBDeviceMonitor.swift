//
//  USBDeviceMonitor.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 6/12/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa


public class USBDeviceMonitor<T: USBDevice, M: USBDeviceManager<T>>: NSObject {
    private var currentThread:Thread?
    public var deviceManager:M

    public init(_ deviceManager:M) {
        self.deviceManager = deviceManager
        print(self.deviceManager)
    }
    public func start() -> Thread {
        if (self.currentThread != nil) {
            return self.currentThread!
        }
        self.currentThread = Thread(target: self, selector:#selector(self.initMonitor), object: nil)
        self.currentThread!.start()
        return self.currentThread!
    }
    
    public func isRunning() -> Bool {
        return (self.currentThread != nil) ? true : false
    }
    
    public func cancel() {
        if (self.currentThread != nil) {
            self.currentThread!.cancel()
        }
    }
    
    public func initMonitor() {
        var matchedIterator:io_iterator_t = 0
        var removalIterator:io_iterator_t = 0
        let notifyPort:IONotificationPortRef = IONotificationPortCreate(kIOMasterPortDefault)
        IONotificationPortSetDispatchQueue(notifyPort, DispatchQueue(label: "IODetector"))
        
        for vp in self.deviceManager.vp {
            let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
                as NSMutableDictionary
            matchingDict[kUSBVendorID] = NSNumber(value: vp.vendorId)
            matchingDict[kUSBProductID] = NSNumber(value: vp.productId)
            
            let matchingCallback:IOServiceMatchingCallback = { (userData, iterator) in
                // Convert self to a void pointer, store that in the context, and convert it back to an object pointer
                let this = Unmanaged<USBDeviceMonitor<USBDevice, USBDeviceManager<USBDevice>>>
                    .fromOpaque(userData!).takeUnretainedValue()
                this.rawDeviceAdded(iterator: iterator)
            }
            
            let removalCallback: IOServiceMatchingCallback = {
                (userData, iterator) in
                let this = Unmanaged<USBDeviceMonitor<USBDevice, USBDeviceManager<USBDevice>>>
                    .fromOpaque(userData!).takeUnretainedValue()
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
    
    
    private func rawDeviceAdded(iterator: io_iterator_t) {
        
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            var score:Int32 = 0
            var kr:Int32 = 0
            
            var deviceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
            var plugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
            var interfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
            
            
            var deviceID:UInt64 = 0
            let deviceIDResult = IORegistryEntryGetRegistryEntryID(usbDevice, &deviceID)
            
            if(deviceIDResult != kIOReturnSuccess) {
                print("Error getting device id")
            }
            
            print("device \(deviceID)")
            
            // io_name_t imports to swift as a tuple (Int8, ..., Int8) 128 ints
            // although in device_types.h it's defined:
            // typedef	char io_name_t[128];
            var deviceNameCString: [CChar] = [CChar](repeating: 0, count: 128)
            let deviceNameResult = IORegistryEntryGetName(usbDevice, &deviceNameCString)
            
            if(deviceNameResult != kIOReturnSuccess) {
                print("Error getting device name")
            }
            
            let deviceName = String.init(cString: &deviceNameCString)
            
            // Get plugInInterface for current USB device
            let plugInInterfaceResult = IOCreatePlugInInterfaceForService(
                usbDevice,
                kIOUSBDeviceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterfacePtrPtr,
                &score)
            
            // USB device object is no longer needed.
            IOObjectRelease(usbDevice)
            
            // Dereference pointer for the plug-in interface
            guard plugInInterfaceResult == kIOReturnSuccess,
                let plugInInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
                    print("Unable to get Plug-In Interface")
                    continue
            }
            
            // use plug in interface to get a device interface
            let deviceInterfaceResult = withUnsafeMutablePointer(to: &deviceInterfacePtrPtr) {
                $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                    plugInInterface.QueryInterface(
                        plugInInterfacePtrPtr,
                        CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                        $0)
                }
            }
            
            // dereference pointer for the device interface
            guard deviceInterfaceResult == kIOReturnSuccess,
                let deviceInterface = deviceInterfacePtrPtr?.pointee?.pointee else {
                    print("Unable to get Device Interface")
                    continue
            }
            
            kr = deviceInterface.USBDeviceOpen(deviceInterfacePtrPtr)
            
            if (kr != kIOReturnSuccess)
            {
                print("Could not open device (error: \(kr))")
                continue
            }
            else if (kr == kIOReturnExclusiveAccess)
            {
                // this is not a problem as we can still do some things
                continue
            }
            
            
            var vid:UInt16 = 0;
            kr = deviceInterface.GetDeviceVendor(deviceInterfacePtrPtr, &vid)
            assert(kr == kIOReturnSuccess)
            
            var pid:UInt16 = 0;
            kr = deviceInterface.GetDeviceVendor(deviceInterfacePtrPtr, &pid)
            assert(kr == kIOReturnSuccess)
            let _ = self.deviceManager.add(id:deviceID, vendorId: vid, productId: pid, deviceName: deviceName)
        }
    }
    
    private func rawDeviceRemoved(iterator: io_iterator_t) {
        
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            var kr:Int32 = 0
            
            var deviceID:UInt64 = 0
            let deviceIDResult = IORegistryEntryGetRegistryEntryID(usbDevice, &deviceID)
            
            if(deviceIDResult != kIOReturnSuccess) {
                print("Error getting device id")
            }
            
            print("device disconnect \(deviceID)")
            
            // USB device object is no longer needed.
            kr = IOObjectRelease(usbDevice)
            
            if (kr != kIOReturnSuccess)
            {
                print("Couldn’t release raw device object (error: \(kr))")
                continue
            }
            
            let _ = self.deviceManager.remove(id: deviceID)
        }
    }
}

