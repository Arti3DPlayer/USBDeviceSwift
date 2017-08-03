# USBDeviceSwift

**USBDeviceSwift** - is a wrapper for `IOKit.usb` and `IOKit.hid` written on pure Swift that allows you convenient work with USB devices.

<table>
    <tr>
        <th>
            <img src="STM32DeviceExample/Media/stm32example.gif"/>
        </th>
        <th>
            <img src="RaceflightControllerHIDExample/Media/rfHIDExample.gif"/>
        </th>
    </tr>
</table>

## Getting Started

### Requirements

* Mac OS X 10.10
* Xcode 8+
* Swift 3

## Installation

#### CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects.

Specify USBDeviceSwift into your project's `Podfile`:

```ruby
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'testusb' do
# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

# Pods for testusb

pod 'USBDeviceSwift'

end
```

Then run the following command:

```bash
$ pod install
```

#### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/)

```
import PackageDescription

let package = Package(
    name: "Example project",
    dependencies: [
        .Package(url: "https://github.com/Arti3DPlayer/USBDeviceSwift.git", majorVersion: 1),
    ]
)
```

### USB device communication

Create `USBDeviceMonitor` object globally, set `vid` and `pid` of devices that you need to listen and run monitor in new thread for listen USB devices

```

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
}

```

*note* - `start` function using `RunLoop` that blocks thread don't run monitor in `Main` thread

There are two global notifications:

```
USBDeviceConnected

USBDeviceDisconnected
```

Listen them in our ViewController:

```
class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        NotificationCenter.default.addObserver(self, selector: #selector(self.usbConnected), name: .USBDeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbDisconnected), name: .USBDeviceDisconnected, object: nil)
    }

    // getting connected device data
    func usbConnected(notification: NSNotification) {
         guard let nobj = notification.object as? NSDictionary else {
             return
         }

         guard let deviceInfo:USBDevice = nobj["device"] as? USBDevice else {
             return
         }
    }

    // getting disconnected device id
    func usbDisconnected(notification: NSNotification) {
         guard let nobj = notification.object as? NSDictionary else {
             return
         }

        guard let deviceInfo:USBDevice = nobj["id"] as? UInt64 else {
            return
        }
    }
}
```

```USBDeviceConnected``` notification - returns `USBDevice` with all basic info

* id - returns id from [IORegistryEntryGetRegistryEntryID](https://developer.apple.com/documentation/iokit/1514719-ioregistryentrygetregistryentryi)
* vendorId - Vendor ID from [GetDeviceVendor](https://developer.apple.com/documentation/iokit/iousbinterfaceinterface800/1639594-getdevicevendor?preferredLanguage=occ)
* productId -  Product ID from [GetDeviceProduct](https://developer.apple.com/documentation/iokit/iousbinterfaceinterface192/1558993-getdeviceproduct?language=objc)
* name - Name from [IORegistryEntryGetName](https://developer.apple.com/documentation/iokit/1514323-ioregistryentrygetname?preferredLanguage=occ)

* deviceInterfacePtrPtr - Pointer to [IOUSBDeviceInterface](https://developer.apple.com/documentation/iokit/iousbdeviceinterface?preferredLanguage=occ)
* plugInInterfacePtrPtr - Pointer to [IOCFPlugInInterface](https://developer.apple.com/documentation/iokit/iocfplugininterface?language=objc)

```USBDeviceDisconnected``` notification - returns id from [IORegistryEntryGetRegistryEntryID](https://developer.apple.com/documentation/iokit/1514719-ioregistryentrygetregistryentryi)



#### Send command to USB device example:
```
enum STM32DeviceError: Error {
    case DeviceInterfaceNotFound
    case InvalidData(desc:String)
    case RequestError(desc:String)
}

func getStatus() throws -> [UInt8] {
    //Getting device interface from our pointer
    guard let deviceInterface = self.deviceInfo.deviceInterfacePtrPtr?.pointee?.pointee else {
        throw STM32DeviceError.DeviceInterfaceNotFound
    }

    var kr:Int32 = 0
    let length:Int = 6
    var requestPtr:[UInt8] = [UInt8](repeating: 0, count: length)
    // Creating request
    var request = IOUSBDevRequest(bmRequestType: 161,
                                  bRequest: 0x03,
                                  wValue: 0,
                                  wIndex: 0,
                                  wLength: UInt16(length),
                                  pData: &requestPtr,
                                  wLenDone: 255)

    kr = deviceInterface.DeviceRequest(self.deviceInfo.deviceInterfacePtrPtr, &request)

    if (kr != kIOReturnSuccess) {
        throw STM32DeviceError.RequestError(desc: "Get device status request error: \(kr)")
    }

    // Getting our data
    return requestPtr
}
```

See full example in `STM32DeviceExample` folder

### HID device communication

Create `HIDDeviceMonitor` object globally, set `vid` and `pid` of devices and reportSize for communication and run monitor in new thread for listen HID devices

```

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

}

```

*note* - `start` function using `RunLoop` that blocks thread don't run monitor in `Main` thread

There are three global notifications:

```
HIDDeviceDataReceived

HIDDeviceConnected

HIDDeviceDisconnected
```

Listen them in our ViewController:

```
class ViewController: NSViewController {    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var connectedDevice:RFDevice?
    var devices:[RFDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbConnected), name: .HIDDeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbDisconnected), name: .HIDDeviceDisconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hidReadData), name: .HIDDeviceDataReceived, object: nil)
    }

    
    func usbConnected(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let deviceInfo:HIDDevice = nobj["device"] as? HIDDevice else {
            return
        }
    }
    
    func usbDisconnected(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let id:String = nobj["id"] as? String else {
            return
        }
    }
    
    func hidReadData(notification: Notification) {
        let obj = notification.object as! NSDictionary
        let data = obj["data"] as! Data
    }
    
}
```

`HIDDevice` has all basic info:

`id` - [kIOHIDLocationIDKey](https://developer.apple.com/documentation/iokit/kiohidlocationidkey?language=objc) - property converted to `String

`vendorId` - [kIOHIDVendorIDKey](https://developer.apple.com/documentation/iokit/kiohidvendoridkey?language=objc) - property converted to `Int`

`productId` - [kIOHIDProductIDKey](https://developer.apple.com/documentation/iokit/kiohidproductidkey?language=objc) - property converted to `Int`

`reportSize` - device specific

`device` - reference to [IOHIDDevice](https://developer.apple.com/documentation/kernel/iohiddevice?language=objc)

`name` - [kIOHIDProductKey](https://developer.apple.com/documentation/iokit/kiohidproductkey?language=objc) - property converted to `String`

To get additional properites from device use [IOHIDDeviceGetProperty](https://developer.apple.com/documentation/iokit/1588648-iohiddevicegetproperty). Example:

`IOHIDDeviceGetProperty(HIDDevice.device, kIOHIDMaxInputReportSizeKey as CFString) as? Int`




#### Send command to USB device example:

```
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
```

See full example in `RaceflightControllerHIDExample` folder

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details

## Change Log

This can be found in the [CHANGELOG.md](CHANGELOG.md) file.

