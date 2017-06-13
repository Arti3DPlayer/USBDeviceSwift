# USBDeviceSwift

**USBDeviceSwift** - is a wrapper for IOKit.usb written on pure Swift that allows you convenient work with USB devices.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Requirements

* Mac OS X 10.10
* Xcode 8+
* Swift 3

### Usage

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

        guard let deviceInfo:USBDevice = nobj["device"] as? USBDevice else {
            return
        }
    }
}
```

```USBDeviceConnected``` notification - returns `USBDevice` with all basic info

id - returns id from [IORegistryEntryGetRegistryEntryID](https://developer.apple.com/documentation/iokit/1514719-ioregistryentrygetregistryentryi)
vendorId - Vendor ID from [GetDeviceVendor](https://developer.apple.com/documentation/iokit/iousbinterfaceinterface800/1639594-getdevicevendor?preferredLanguage=occ)
productId -  Product ID from [GetDeviceProduct](https://developer.apple.com/documentation/iokit/iousbinterfaceinterface192/1558993-getdeviceproduct?language=objc)
name - Name from [IORegistryEntryGetName](https://developer.apple.com/documentation/iokit/1514323-ioregistryentrygetname?preferredLanguage=occ)

deviceInterfacePtrPtr - Pointer to [IOUSBDeviceInterface](https://developer.apple.com/documentation/iokit/iousbdeviceinterface?preferredLanguage=occ)
plugInInterfacePtrPtr - Pointer to [IOCFPlugInInterface](https://developer.apple.com/documentation/iokit/iocfplugininterface?language=objc)

```USBDeviceDisconnected``` notification - returns id from [IORegistryEntryGetRegistryEntryID](https://developer.apple.com/documentation/iokit/1514719-ioregistryentrygetregistryentryi)



Send command to USB device example:
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


### Installing

A step by step series of examples that tell you have to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc

