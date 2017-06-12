//
//  STM32Device.swift
//  STM32DeviceExample
//
//  Created by Artem Hruzd on 6/12/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift


enum DFUREQUEST:UInt8 {
    case DETACH=0x00 // OUT, Requests the device to leave DFU mode and enter the application.
    case DNLOAD=0x01 // OUT, Requests data transfer from Host to the device in order to load them into device internal Flash. Includes also erase commands
    case UPLOAD=0x02 // IN,  Requests data transfer from device to Host in order to load content of device internal Flash into a Host file.
    case GETSTATUS=0x03 // IN,  Requests device to send status report to the Host (including status resulting from the last request execution and the state the device will enter immediately after this request).
    case CLRSTATUS=0x04 // OUT, Requests device to clear error status and move to next step
    case GETSTAT=0x05 // IN,  Requests the device to send only the state it will enter immediately after this request.
    case ABORT=0x06  // OUT, Requests device to exit the current state/operation and enter idle state immediately.
}


enum DFUSTATUS:UInt8 {
    case OK = 0x00 // No error condition is present.
    case errTARGET = 0x01 // File is not targeted for use by this device.
    case errFILE = 0x02 // File is for this device but fails some vendor-specific verification test
    case errWRITE = 0x03 // Device is unable to write memory.
    case errERASE = 0x04 // Memory erase function failed.
    case errCHECK_ERASED = 0x05 // Memory erase check failed.
    case errPROG = 0x06 // Program memory function failed.
    case errVERIFY = 0x07 // Programmed memory failed verification.
    case errADDRESS = 0x08 // Cannot program memory due to received address that is out of range.
    case errNOTDONE = 0x09 // Received DFU_DNLOAD with wLength = 0, but device does not think it has all of the data yet.
    case errFIRMWARE = 0x0A // Device's firmware is corrupt. It cannot return to run-time (non-DFU) operations.
    case errVENDOR = 0x0B // iString indicates a vendor-specific error.
    case errUSBR = 0x0C // Device detected unexpected USB reset signaling.
    case errPOR = 0x0D // Device detected unexpected power on reset.
    case errUNKNOWN = 0x0E // Something went wrong, but the device does not know what it was.
    case errSTALLEDPKT = 0x0F  // Device stalled an unexpected request.
}

enum DFUSTATE:UInt8 {
    case appIDLE = 0 // Device is running its normal application.
    case appDETACH = 1 // Device is running its normal application, has received the DFU_DETACH request, and is waiting for a USB reset.
    case dfuIDLE = 2 // Device is operating in the DFU mode and is waiting for requests.
    case dfuDNLOAD_SYNC = 3 // Device has received a block and is waiting for the host to solicit the status via DFU_GETSTATUS.
    case dfuDNBUSY = 4 // Device is programming a control-write block into its nonvolatile memories.
    case dfuDNLOAD_IDLE = 5 // Device is processing a download operation. Expecting DFU_DNLOAD requests.
    case dfuMANIFEST_SYNC = 6 // Device has received the final block of firmware from the host and is waiting for receipt of DFU_GETSTATUS to begin the Manifestation phase; or device has completed the Manifestation phase and is waiting for receipt of DFU_GETSTATUS.
    case dfuMANIFEST = 7 // Device is in the Manifestation phase. (Not all devices will be able to respond to DFU_GETSTATUS when in this state.)
    case dfuMANIFEST_WAIT_RESET = 8 // Device has programmed its memories and is waiting for a USB reset or a power on reset. (Devices that must enter this state clear bitManifestationTolerant to 0.)
    case dfuUPLOAD_IDLE = 9 // The device is processing an upload operation. Expecting DFU_UPLOAD requests.
    case dfuERROR = 10 // An error has occurred. Awaiting the DFU_CLRSTATUS request.
}


class STM32Device: USBDevice {
    var deviceMyName:String = "Default"
    
    public required init(id:UInt64, vendorId:UInt16, productId:UInt16, deviceName:String = "Unnamed USB Device") {
        super.init(id:id, vendorId:vendorId, productId:productId, deviceName:deviceName)
    }
    
    func getStatus() throws -> [UInt8] {
        guard let deviceInterface = self.deviceInterfacePtrPtr?.pointee?.pointee else {
            throw DFUDeviceError.DeviceInterfaceNotFound
        }
        
        var kr:Int32 = 0
        let length:Int = 6
        var requestPtr:[UInt8] = [UInt8](repeating: 0, count: length)
        var request = IOUSBDevRequest(bmRequestType: 161,
                                      bRequest: DFUREQUEST.GETSTATUS.rawValue,
                                      wValue: 0,
                                      wIndex: 0,
                                      wLength: UInt16(length),
                                      pData: &requestPtr,
                                      wLenDone: 255)
        
        kr = deviceInterface.DeviceRequest(self.deviceInterfacePtrPtr, &request)
        
        if (kr != kIOReturnSuccess) {
            throw DFUDeviceError.RequestError(desc: "Get device status request error: \(kr)")
        }
        
        return requestPtr
    }
}

class STM32DeviceManager: USBDeviceManager<USBDevice> {
    
    
    override func add(id: UInt64, vendorId: UInt16, productId: UInt16, deviceName: String) -> USBDevice {
        var device = super.add(id: id, vendorId: vendorId, productId: productId)
        print("my")
        return device
    }

}

