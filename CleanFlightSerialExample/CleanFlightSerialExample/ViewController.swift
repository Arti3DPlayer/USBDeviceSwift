//
//  ViewController.swift
//  SerialDeviceSwift
//
//  Created by Artem Hruzd on 3/9/18.
//  Copyright © 2018 Artem Hruzd. All rights reserved.
//

import Cocoa
import USBDeviceSwift

class ViewController: NSViewController {
    @IBOutlet weak var devicesComboBox: NSComboBox!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var connectedDeviceLabel: NSTextField!
    @IBOutlet weak var serialDeviceView: NSView!
    
    @IBAction func connectDevice(_ sender: Any) {
        DispatchQueue.main.async {
            if (self.devices.count > 0) {
                let device = self.devices[0]
                if (self.connectedDevice != nil) {
                    self.connectedDevice?.closePort()
                    self.connectButton.title = "Open port"
                    self.devicesComboBox.isEnabled = true
                    self.connectedDevice = nil
                    self.serialDeviceView.isHidden = true
                } else {
                    do {
                        try device.openPort(toReceive: true, andTransmit: true)
                    } catch PortError.failedToOpen {
                        self.dialogOK(question: "Error", text: "Serial port \(device.deviceInfo.path) failed to open.")
                    } catch {
                        self.dialogOK(question: "Error", text: "\(error)")
                    }
                    self.connectButton.title = "Close port"
                    self.devicesComboBox.isEnabled = false
                    self.connectedDevice = device
                    self.connectedDeviceLabel.stringValue = "Port opened: \(device.deviceInfo.path) (\(String(describing: device.deviceInfo.vendorId)), \(String(describing: device.deviceInfo.productId)))"
                    self.serialDeviceView.isHidden = false
                }
            }
        }
    }
    
    var connectedDevice:CleanFlightDevice?
    var devices:[CleanFlightDevice] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialDeviceAdded), name: .SerialDeviceAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialDeviceRemoved), name: .SerialDeviceRemoved, object: nil)
        
        self.devicesComboBox.isEditable = false
        self.devicesComboBox.completes = false
        self.serialDeviceView.isHidden = true
        self.devicesComboBox.reloadData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc func serialDeviceAdded(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let deviceInfo:SerialDevice = nobj["device"] as? SerialDevice else {
            return
        }
        let device = CleanFlightDevice(deviceInfo)
        DispatchQueue.main.async {
            self.devices.append(device)
            self.devicesComboBox.reloadData()
        }
    }

    @objc func serialDeviceRemoved(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let deviceInfo:SerialDevice = nobj["device"] as? SerialDevice else {
            return
        }
        DispatchQueue.main.async {
            if let index = self.devices.index(where: { $0.deviceInfo.path == deviceInfo.path }) {
                self.devices.remove(at: index)
                if (deviceInfo.path == self.connectedDevice?.deviceInfo.path) {
                    self.connectButton.title = "Connect"
                    self.devicesComboBox.isEnabled = true
                    self.connectedDevice = nil
                    self.serialDeviceView.isHidden = true
                }
            }
            self.devicesComboBox.reloadData()
        }
    }
    
    func dialogOK(question: String, text: String, style:NSAlert.Style = .warning) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = question
        myPopup.informativeText = text
        myPopup.alertStyle = style
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }

    
}

extension ViewController: NSComboBoxDataSource {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return self.devices.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return self.devices[index].deviceInfo.name
    }
}

