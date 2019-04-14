# LocationPicker

[![CI Status](https://img.shields.io/travis/200739491@qq.com/LocationPicker.svg?style=flat)](https://travis-ci.org/200739491@qq.com/LocationPicker)
[![Version](https://img.shields.io/cocoapods/v/LocationPicker.svg?style=flat)](https://cocoapods.org/pods/LocationPicker)
[![License](https://img.shields.io/cocoapods/l/LocationPicker.svg?style=flat)](https://cocoapods.org/pods/LocationPicker)
[![Platform](https://img.shields.io/cocoapods/p/LocationPicker.svg?style=flat)](https://cocoapods.org/pods/LocationPicker)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

LocationPicker is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LocationPicker'
```

## Use

````swift
import CoreLocation
import LocationPicker

class ViewController: UIViewController {

    @IBOutlet weak var descLabel: UILabel!
    
    @IBAction func selectLocation(){
        
        let viewController = LocationPickerViewController()
        
        viewController.pickerDelegate = self
        
        self.present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: LocationPickerViewControllerDelegate{
    
    func userDidCancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func userSelectLocation(placemark: CLPlacemark) {
        
        self.dismiss(animated: true, completion: nil)
        
        descLabel.text = placemark.formatString
    }
}

````

## preview

![](docs/Assets/IMG_1350.PNG)

-------

![](docs/Assets/IMG_1351.PNG)

-------

![](docs/Assets/IMG_1352.PNG)

-------

![](docs/Assets/IMG_1353.PNG)

## Author

200739491@qq.com, 200739491@qq.com

## License

LocationPicker is available under the MIT license. See the LICENSE file for more info.
