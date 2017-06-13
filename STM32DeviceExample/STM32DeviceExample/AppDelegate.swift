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
    //make sure that stm32DeviceMonitor always exist
    let stm32DeviceMonitor = USBDeviceMonitor([
        VIDPID(vendorId: 0x0483, productId: 0xdf11)
        ])

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let stm32DeviceDaemon = Thread(target: stm32DeviceMonitor, selector:#selector(stm32DeviceMonitor.start), object: nil)
        stm32DeviceDaemon.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

