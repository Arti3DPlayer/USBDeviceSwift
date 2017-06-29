//
//  RFDevice.swift
//  RaceflightControllerHIDExample
//
//  Created by Artem Hruzd on 6/17/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift

class RFDevice: NSObject {
    let deviceInfo:HIDDevice
    
    required init(_ deviceInfo:HIDDevice) {
        self.deviceInfo = deviceInfo
    }
    
    func sendCommad(command:String) {
        let safeStr = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if let commandData = safeStr.data(using: .utf8) {
            self.write(commandData)
        }
    }
    
    func write(_ data: Data) {
        var bytesArray = [UInt8](data)
        let reportId:UInt8 = 2
        bytesArray.insert(reportId, at: 0)
        bytesArray.append(0)// hack every report should end with 0 byte
        
        if (bytesArray.count > self.deviceInfo.reportSize) {
            print("Output data too large for USB report")
            return
        }
        
        let correctData = Data(bytes: UnsafePointer<UInt8>(bytesArray), count: self.deviceInfo.reportSize)
        
        IOHIDDeviceSetReport(
            self.deviceInfo.device,
            kIOHIDReportTypeOutput,
            CFIndex(reportId),
            (correctData as NSData).bytes.bindMemory(to: UInt8.self, capacity: correctData.count),
            correctData.count
        )
    }
    
    // Additional: convertion bytes to specific string, removing garbage etc.
    func convertByteDataToString(_ data:Data, removeId:Bool=true, cleanGarbage:Bool=true) -> String {
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
        if (array.count>0 && removeId) {
            array.remove(at: 0)
        }
        var strResp:String = ""
        for byte in array {
            strResp += String(UnicodeScalar(byte))
        }
        if (cleanGarbage) {
            if let dotRange = strResp.range(of: "\0") {
                strResp.removeSubrange(dotRange.lowerBound..<strResp.endIndex)
            }
        }
        strResp = strResp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return strResp
    }
}
