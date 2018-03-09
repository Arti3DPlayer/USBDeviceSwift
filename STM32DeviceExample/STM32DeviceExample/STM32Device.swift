//
//  STM32Device.swift
//  STM32DeviceExample
//
//  Created by Artem Hruzd on 6/12/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift


enum STM32REQUEST:UInt8 {
    case DETACH=0x00 // OUT, Requests the device to leave DFU mode and enter the application.
    case DNLOAD=0x01 // OUT, Requests data transfer from Host to the device in order to load them into device internal Flash. Includes also erase commands
    case UPLOAD=0x02 // IN,  Requests data transfer from device to Host in order to load content of device internal Flash into a Host file.
    case GETSTATUS=0x03 // IN,  Requests device to send status report to the Host (including status resulting from the last request execution and the state the device will enter immediately after this request).
    case CLRSTATUS=0x04 // OUT, Requests device to clear error status and move to next step
    case GETSTAT=0x05 // IN,  Requests the device to send only the state it will enter immediately after this request.
    case ABORT=0x06  // OUT, Requests device to exit the current state/operation and enter idle state immediately.
}

enum STM32DeviceError: Error {
    case DeviceInterfaceNotFound
    case InvalidData(desc:String)
    case RequestError(desc:String)
}

class STM32Device {
    var deviceInfo:USBDevice
    
    required init(_ deviceInfo:USBDevice) {
        self.deviceInfo = deviceInfo
    }
    
    func getStatus() throws -> [UInt8] {
        //Getting device interface from our pointer
        guard let deviceInterface = self.deviceInfo.deviceInterfacePtrPtr?.pointee?.pointee else {
            throw STM32DeviceError.DeviceInterfaceNotFound
        }
        
        var kr:Int32 = 0
        let length:Int = 6
        var requestPtr:[UInt8] = [UInt8](repeating: 0, count: length)
        // Creating request
        var request = IOUSBDevRequest(bmRequestType: 161,
                                      bRequest: STM32REQUEST.GETSTATUS.rawValue,
                                      wValue: 0,
                                      wIndex: 0,
                                      wLength: UInt16(length),
                                      pData: &requestPtr,
                                      wLenDone: 255)
        
        kr = deviceInterface.DeviceRequest(self.deviceInfo.deviceInterfacePtrPtr, &request)
        
        if (kr != kIOReturnSuccess) {
            throw STM32DeviceError.RequestError(desc: "Get device status request error: \(kr)")
        }
        
        return requestPtr
    }
}

