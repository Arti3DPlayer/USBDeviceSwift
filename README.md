# USBDeviceSwift

**USBDeviceSwift** - is a wrapper for `IOKit.usb` and `IOKit.hid` written on pure Swift that allows you convenient work with USB devices.

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
        .Package(url: "https://github.com/Arti3DPlayer/USBDeviceSwift.git", majorVersion: 0),
    ]
)
```

### Usage

<table>
    <tr>
        <th>
            <img src="STM32DeviceExample/Media/stm32example.gif"/>
        </th>
    </tr>
</table>


#### USB device communication

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
    func usbConnected(notification: NSNotification) {
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

#### HID device communication

In progress

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details

## Change Log

This can be found in the [CHANGELOG.md](CHANGELOG.md) file.

