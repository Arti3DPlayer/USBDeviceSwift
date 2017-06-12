//
//  AppDelegate.swift
//  STM32DeviceExample
//
//  Created by Artem Hruzd on 6/11/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var dfuDeviceManager = USBDeviceManager([VIDPID(vendorId: 0x0483, productId: 0xdf11)])
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let dfuDeviceMonitor = USBDeviceMonitor(self.dfuDeviceManager)
        dfuDeviceMonitor.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    

}

