//
//  AppDelegate.swift
//  RaceflightControllerHIDExample
//
//  Created by Artem Hruzd on 6/14/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    //make sure that rfDeviceMonitor always exist
    let rfDeviceMonitor = HIDDeviceMonitor([
        HIDMonitorData(vendorId: 0x0483, productId: 0x5742)
        ], reportSize: 64)


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let rfDeviceDaemon = Thread(target: self.rfDeviceMonitor, selector:#selector(self.rfDeviceMonitor.start), object: nil)
        rfDeviceDaemon.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

