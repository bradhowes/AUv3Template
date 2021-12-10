// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/**
 Controller for a knob and text view / label.
 */
final class KnobController: NSObject, AUParameterControl {
  private let log = Logging.logger("KnobController")

  private let logSliderMinValue: Float = 0.0
  private let logSliderMaxValue: Float = 9.0
  private lazy var logSliderMaxValuePower2Minus1 = Float(pow(2, logSliderMaxValue) - 1)

  private let parameterObserverToken: AUParameterObserverToken

  let parameter: AUParameter
  let formatter: (AUValue) -> String
  let knob: Knob
  let label: Label

  private let useLogValues: Bool
  private var restoreNameTimer: Timer?
  private var hasActiveLabel: Bool = false

  init(parameterObserverToken: AUParameterObserverToken, parameter: AUParameter,
       formatter: @escaping (AUValue) -> String, knob: Knob, label: Label,
       logValues: Bool)
  {
    self.parameterObserverToken = parameterObserverToken
    self.parameter = parameter
    self.formatter = formatter
    self.knob = knob
    self.label = label
    self.useLogValues = logValues
    super.init()

    self.label.text = parameter.displayName
    #if os(macOS)
    self.label.delegate = self
    self.label.onFocusChange = onFocusChanged
    #endif

    if useLogValues {
      knob.minimumValue = logSliderMinValue
      knob.maximumValue = logSliderMaxValue
      knob.value = logKnobLocationForParameterValue()
    } else {
      knob.minimumValue = parameter.minValue
      knob.maximumValue = parameter.maxValue
      knob.value = parameter.value
    }
  }
}

extension KnobController {
  func setEditedValue(_ value: AUValue) {
    os_log(.info, log: log, "setEditedValue - value: %f", value)
    var value = value
    if value < parameter.minValue || value > parameter.maxValue {
      os_log(.info, log: log, "out of bounds: %f", value)
      value = parameter.value
    }

    os_log(.info, log: log, "applying value: %f", value)

    if value != parameter.value {
      parameter.setValue(value, originator: parameterObserverToken)
      knob.value = useLogValues ? logKnobLocationForParameterValue() : value
    }
    showNewValue(value)
  }

  func controlChanged() {
    os_log(.info, log: log, "controlChanged - %f", knob.value)
    #if os(macOS)
    NSApp.keyWindow?.makeFirstResponder(nil)
    #endif
    let value = useLogValues ? parameterValueForLogSliderLocation() : knob.value
    showNewValue(value)
    parameter.setValue(value, originator: parameterObserverToken)
  }

  func parameterChanged() {
    os_log(.info, log: log, "parameterChanged - %f", parameter.value)
    showNewValue(parameter.value)
    knob.value = useLogValues ? logKnobLocationForParameterValue() : parameter.value
  }
}

extension KnobController {
  #if os(macOS)
  private func onFocusChanged(hasFocus: Bool) {
    os_log(.info, log: log, "onFocusChanged - hasFocus: %d", hasFocus)
    if hasFocus {
      hasActiveLabel = true
      os_log(.info, log: log, "showing parameter value: %f", parameter.value)
      label.floatValue = parameter.value
      restoreNameTimer?.invalidate()
    } else if hasActiveLabel {
      hasActiveLabel = false
      setEditedValue(label.floatValue)
    }
  }
  #endif

  private func logKnobLocationForParameterValue() -> Float {
    log2(((parameter.value - parameter.minValue) / (parameter.maxValue - parameter.minValue)) *
      logSliderMaxValuePower2Minus1 + 1.0)
  }

  private func parameterValueForLogSliderLocation() -> AUValue {
    ((pow(2, knob.value) - 1) / logSliderMaxValuePower2Minus1) * (parameter.maxValue - parameter.minValue) +
      parameter.minValue
  }

  private func showNewValue(_ value: AUValue) {
    os_log(.info, log: log, "showNewValue: %f", value)
    label.text = formatter(value)
    restoreName()
  }

  private func restoreName() {
    restoreNameTimer?.invalidate()
    let displayName = parameter.displayName
    let label = self.label
    restoreNameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      os_log(.info, log: self.log, "restoreName: %{public}s", displayName)
      #if os(iOS)
      UIView.transition(with: self.label, duration: 0.5, options: [.curveLinear, .transitionCrossDissolve]) {
        label.text = displayName
      } completion: { _ in
        label.text = displayName
      }
      #else
      label.text = displayName
      #endif
    }
  }
}

#if os(macOS)
extension KnobController: NSTextFieldDelegate {
  func controlTextDidEndEditing(_ obj: Notification) {
    os_log(.info, log: log, "controlTextDidEndEditing")
    label.onFocusChange(false)
    NSApp.keyWindow?.makeFirstResponder(nil)
  }
}
#endif
