//
//  CleanFlightDevice.swift
//  SerialDeviceSwift
//
//  Created by Artem Hruzd on 3/9/18.
//  Copyright © 2018 Artem Hruzd. All rights reserved.
//

import Foundation
import IOKit.serial
import USBDeviceSwift

public enum PortError: Int32, Error {
    case failedToOpen = -1 // refer to open()
    case invalidPath
    case mustReceiveOrTransmit
    case mustBeOpen
    case stringsMustBeUTF8
}

class CleanFlightDevice {
    var deviceInfo:SerialDevice
    var fileDescriptor:Int32?
    
    required init(_ deviceInfo:SerialDevice) {
        self.deviceInfo = deviceInfo
    }
    
    func openPort(toReceive receive: Bool, andTransmit transmit: Bool) throws {
        guard !deviceInfo.path.isEmpty else {
            throw PortError.invalidPath
        }
        
        guard receive || transmit else {
            throw PortError.mustReceiveOrTransmit
        }

        var readWriteParam : Int32
        
        if receive && transmit {
            readWriteParam = O_RDWR
        } else if receive {
            readWriteParam = O_RDONLY
        } else if transmit {
            readWriteParam = O_WRONLY
        } else {
            fatalError()
        }
    
        fileDescriptor = open(deviceInfo.path, readWriteParam | O_NOCTTY | O_EXLOCK)
        
        // Throw error if open() failed
        if fileDescriptor == PortError.failedToOpen.rawValue {
            throw PortError.failedToOpen
        }
    }
    
    public func closePort() {
        if let fileDescriptor = fileDescriptor {
            close(fileDescriptor)
        }
        fileDescriptor = nil
    }
}
