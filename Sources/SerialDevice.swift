//
//  SerialDevice.swift
//  USBDeviceSwift
//
//  Created by Artem Hruzd on 3/9/18.
//  Copyright © 2018 Artem Hruzd. All rights reserved.
//

import Foundation
import IOKit.serial


public struct SerialDevice {
    let path:String
    var name:String? // USB Product Name
    var vendorName:String? //USB Vendor Name
    var serialNumber:String? //USB Serial Number
    var vendorId:Int? //USB Serial Number
    var productId:Int? //USB Serial Number
    
    init(path:String) {
        self.path = path
    }
}
