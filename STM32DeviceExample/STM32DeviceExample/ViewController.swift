//
//  ViewController.swift
//  STM32DeviceExample
//
//  Created by Artem Hruzd on 6/11/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift

class ViewController: NSViewController, USBDeviceMonitorDelegate, NSComboBoxDataSource {
    @IBOutlet weak var devicesComboBox: NSComboBox!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var connectedDeviceLabel: NSTextField!
    @IBOutlet weak var dfuDeviceView: NSView!
    
    @IBAction func getStatus(_ sender: Any) {
        
    }
    
    @IBAction func connectDevice(_ sender: Any) {
        DispatchQueue.main.async {
            if (self.devices.count > 0) {
                if (self.connectedDevice != nil) {
                    self.connectButton.title = "Connect"
                    self.devicesComboBox.isEnabled = true
                    self.connectedDevice = nil
                    self.dfuDeviceView.isHidden = true
                } else {
                    self.connectButton.title = "Disconnect"
                    self.devicesComboBox.isEnabled = false
                    self.connectedDevice = self.devices[self.devicesComboBox.integerValue]
                    self.connectedDeviceLabel.stringValue = "Connected device: \(self.connectedDevice!.deviceName) (\(self.connectedDevice!.vendorId), \(self.connectedDevice!.productId))"
                    self.dfuDeviceView.isHidden = false
                }
            }
        }
    }
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    var connectedDevice:USBDevice?
    var devices:[USBDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        self.appDelegate.dfuDeviceManager.delegateUSBDeviceMonitor = self
        
        self.devicesComboBox.isEditable = false
        self.dfuDeviceView.isHidden = true
        self.devicesComboBox.reloadData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return self.devices.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return self.devices[index].deviceName
    }

    func usbConnected(_ device: USBDevice) {
        DispatchQueue.main.async {
            print(device.id)
            self.devices = self.appDelegate.dfuDeviceManager.devices
            self.devicesComboBox.reloadData()
        }
    }
    
    func usbDisconnected(_ device: USBDevice) {
        DispatchQueue.main.async {
            self.devices = self.appDelegate.dfuDeviceManager.devices
            self.devicesComboBox.reloadData()
            print(self.connectedDevice?.id)
            if (device.id == self.connectedDevice?.id) {
                self.connectButton.title = "Connect"
                self.devicesComboBox.isEnabled = true
                self.connectedDevice = nil
                self.dfuDeviceView.isHidden = true
            }
        }
    }

}

