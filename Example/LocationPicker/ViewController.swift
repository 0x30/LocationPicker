//
//  ViewController.swift
//  LocationPicker
//
//  Created by 200739491@qq.com on 04/14/2019.
//  Copyright (c) 2019 200739491@qq.com. All rights reserved.
//

import UIKit

import CoreLocation
import LocationPicker

class ViewController: UIViewController, LocationPickerViewControllerDelegate {

    @IBOutlet weak var descLabel: UILabel!
    
    @IBAction func selectLocation(){
        
        let viewController = LocationPickerViewController()
        
        viewController.pickerDelegate = self
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func userDidCancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func userSelectLocation(placemark: CLPlacemark) {
        
        self.dismiss(animated: true, completion: nil)
        
        descLabel.text = placemark.formatString
    }
}

