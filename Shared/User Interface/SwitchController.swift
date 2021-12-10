// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/**
 Controller for a knob and text view / label.
 */
final class SwitchController: AUParameterControl {
  private let log = Logging.logger("SwitchController")

  private let parameterObserverToken: AUParameterObserverToken
  let parameter: AUParameter
  let control: Switch

  init(parameterObserverToken: AUParameterObserverToken, parameter: AUParameter, control: Switch) {
    self.parameterObserverToken = parameterObserverToken
    self.parameter = parameter
    self.control = control
    control.isOn = parameter.value > 0.0 ? true : false
  }
}

extension SwitchController {
  func controlChanged() {
    os_log(.info, log: log, "controlChanged - %f", control.isOn)
    parameter.setValue(control.isOn ? 1.0 : 0.0, originator: parameterObserverToken)
  }

  func parameterChanged() {
    os_log(.info, log: log, "parameterChanged - %f", parameter.value)
    control.isOn = parameter.value > 0.0 ? true : false
  }

  func setEditedValue(_ value: AUValue) {
    parameter.setValue(control.isOn ? 1.0 : 0.0, originator: parameterObserverToken)
  }
}
