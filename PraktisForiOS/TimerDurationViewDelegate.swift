//
//  TimerDurationViewDelegate.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 09/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class TimerDurationViewDelegate : NSObject, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    var mainView: ViewController!
    var timerDurations = [0, 30, 60, 90, 120, 150, 180]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timerDurations.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(timerDurations[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        mainView.timerDuration.text = String(timerDurations[row])
        mainView.timerDurationPicker.isHidden = true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        mainView.timerDurationPicker.isHidden = false
        return false
    }
}
