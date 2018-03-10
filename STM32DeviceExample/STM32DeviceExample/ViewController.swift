//
//  ViewController.swift
//  STM32DeviceExample
//
//  Created by Artem Hruzd on 6/11/17.
//  Copyright © 2017 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift

class ViewController: NSViewController, NSComboBoxDataSource {
    @IBOutlet weak var devicesComboBox: NSComboBox!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var connectedDeviceLabel: NSTextField!
    @IBOutlet weak var dfuDeviceView: NSView!
    @IBOutlet weak var responseLabel: NSTextField!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func getStatus(_ sender: Any) {
        do {
            let status = try self.connectedDevice?.getStatus()
            self.responseLabel.stringValue = "Response: \(status!)"
        } catch {
            self.responseLabel.stringValue = "Response: \(error)"
        }
        
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
                    self.connectedDeviceLabel.stringValue = "Connected device: \(self.connectedDevice!.deviceInfo.name) (\(self.connectedDevice!.deviceInfo.vendorId), \(self.connectedDevice!.deviceInfo.productId))"
                    self.dfuDeviceView.isHidden = false
                }
            }
        }
    }

    var connectedDevice:STM32Device?
    var devices:[STM32Device] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbConnected), name: .USBDeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbDisconnected), name: .USBDeviceDisconnected, object: nil)
        
        self.devicesComboBox.isEditable = false
        self.devicesComboBox.completes = false
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
        return self.devices[index].deviceInfo.name
    }

    @objc func usbConnected(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }

        guard let deviceInfo:USBDevice = nobj["device"] as? USBDevice else {
            return
        }
        let device = STM32Device(deviceInfo)
        DispatchQueue.main.async {
            self.devices.append(device)
            self.devicesComboBox.reloadData()
        }
    }
    
    @objc func usbDisconnected(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let id:UInt64 = nobj["id"] as? UInt64 else {
            return
        }
        DispatchQueue.main.async {
            if let index = self.devices.index(where: { $0.deviceInfo.id == id }) {
                self.devices.remove(at: index)
                if (id == self.connectedDevice?.deviceInfo.id) {
                    self.connectButton.title = "Connect"
                    self.devicesComboBox.isEnabled = true
                    self.connectedDevice = nil
                    self.dfuDeviceView.isHidden = true
                }
            }
            self.devicesComboBox.reloadData()
        }
    }

}

