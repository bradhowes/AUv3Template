// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import os

public protocol AudioUnitParameterCollection: AnyObject {

  /// Factory presets available defined for the audio unit
  var factoryPresets: [AUAudioUnitPreset] {get}

  /// Collection of AUParameter controls for the audio unit
  var parameters: [AUParameter] {get}

  /// The populated parameter tree that contains the runtime parameters to control the audio unit
  var parameterTree: AUParameterTree { get }

  /**
   Apply a factory preset

   - parameter preset: the index of the factory preset to use
   */
  func setValues(preset: Int)
}

/**
 Definitions for the runtime parameters of the filter. Use `@objc` attribute to allow the Obj-C kernel adapter access
 to its API.
 */
@objc public final class AudioUnitParameters: NSObject, AudioUnitParameterCollection {
  private let log = Logging.logger("FilterParameters")

  /// Maximum delay to support (used by kernel)
  @objc public static let maxDelayMilliseconds: AUValue = 15.0

  /// Definitions of the AUParameter controls for the audio unit
  public let parameters: [AUParameter] = [
    AUParameterTree.createParameter(withIdentifier: "depth", name: "Depth", address: .depth,
                                    min: 0.0, max: 100.0, unit: .percent),
    AUParameterTree.createParameter(withIdentifier: "rate", name: "Rate", address: .rate,
                                    min: 0.01, max: 10.0, unit: .hertz),
    AUParameterTree.createParameter(withIdentifier: "delay", name: "Delay", address: .delay,
                                    min: 0.01, max: AudioUnitParameters.maxDelayMilliseconds, unit: .milliseconds),
    AUParameterTree.createParameter(withIdentifier: "feedback", name: "Feedback", address: .feedback,
                                    min: 0.0, max: 100.0, unit: .percent),
    AUParameterTree.createParameter(withIdentifier: "dry", name: "Dry", address: .dryMix,
                                    min: 0.0, max: 100.0, unit: .percent),
    AUParameterTree.createParameter(withIdentifier: "wet", name: "Wet", address: .wetMix,
                                    min: 0.0, max: 100.0, unit: .percent)
  ]

  /// Definitions of the factory presets
  public let factoryPresetValues: [(name: String, preset: FilterPreset)] = [
    ("Flangie", FilterPreset(depth: 100, rate: 0.14, delay: 0.72, feedback: 50, dryMix: 50, wetMix: 50)),
    ("Sweeper", FilterPreset(depth: 100, rate: 0.14, delay: 1.51, feedback: 80, dryMix: 50, wetMix: 50)),
    ("Lord Tremolo", FilterPreset(depth: 100, rate: 8.6, delay: 0.07, feedback: 90, dryMix: 0, wetMix: 100))
  ]

  /// Collection of AUAudioUnitPreset instances that can be used with the audio unit
  public lazy var factoryPresets = factoryPresetValues.enumerated().map { AUAudioUnitPreset(number: $0, name: $1.name) }

  /// AUParameterTree created with the parameter definitions for the audio unit
  public let parameterTree: AUParameterTree

  /**
   Create a new AUParameterTree for the defined filter parameters.

   Installs three closures in the tree:
   - one for providing values
   - one for accepting new values from other sources
   - and one for obtaining formatted string values

   - parameter parameterHandler the object to use to handle the AUParameterTree requests
   */
  init(parameterHandler: AUParameterHandler) {
    self.parameterTree = AUParameterTree.createTree(withChildren: parameters)
    super.init()

    parameterTree.implementorValueObserver = { parameterHandler.set($0, value: $1) }
    parameterTree.implementorValueProvider = { parameterHandler.get($0) }
    parameterTree.implementorStringFromValueCallback = { param, _ in
      let formatted = self.formatValue(param.address.filterParameter, value: param.value)
      os_log(.debug, log: self.log, "parameter %d as string: %d %f %{public}s",
             param.address, param.value, formatted)
      return formatted
    }
  }
}

public extension AudioUnitParameters {

  /// AUParameter that controls the depth setting
  var depth: AUParameter { parameters[.depth] }

  /// AUParameter that controls the rate setting
  var rate: AUParameter { parameters[.rate] }

  /// AUParameter that controls the delay setting
  var delay: AUParameter { parameters[.delay] }

  /// AUParameter that controls the feedback setting
  var feedback: AUParameter { parameters[.feedback] }

  /// AUParameter that controls the dry mix setting
  var dryMix: AUParameter { parameters[.dryMix] }

  /// AUParameter that controls the wet mix setting
  var wetMix: AUParameter { parameters[.wetMix] }
}

public extension AudioUnitParameters {

  /// Allow for subscripting by parameter address
  subscript(address: FilterParameterAddress) -> AUParameter { parameters[address] }

  /**
   Obtain a closure that will return a formatted representation of a given AUValue.

   - parameter address: the AUParameter address to format
   - returns: the formatting closure
   */
  func valueFormatter(_ address: FilterParameterAddress) -> (AUValue) -> String {
    let unitName = self[address].unitName ?? ""

    let separator: String = {
      switch address {
      case .rate, .delay: return " "
      default: return ""
      }
    }()

    let format: String = formatter(address)

    return { value in String(format: format, value) + separator + unitName }
  }

  /**
   Obtain a formatted representation of a given AUValue.

   - parameter address: the address of the parameter to format
   - parameter value: the value to format
   - returns: the formatted representation of the given value
   */
  func formatValue(_ address: FilterParameterAddress?, value: AUValue) -> String {
    guard let address = address else { return "?" }
    let format = formatter(address)
    return String(format: format, value)
  }

  /**
   Accept new values for the filter settings. Uses the AUParameterTree framework for communicating the changes to the
   AudioUnit.
   */
  func setValues(preset: FilterPreset) {
    depth.value = preset.depth
    rate.value = preset.rate
    delay.value = preset.delay
    feedback.value = preset.feedback
    dryMix.value = preset.dryMix
    wetMix.value = preset.wetMix
  }

  func setValues(preset index: Int) {
    setValues(preset: factoryPresetValues[index].preset)
  }
}

extension AudioUnitParameters {

  private func formatter(_ address: FilterParameterAddress) -> String {
    switch address {
    case .depth, .feedback: return "%.2f"
    case .rate: return "%.2f"
    case .delay: return "%.2f"
    case .dryMix, .wetMix: return "%.0f"
    default: return "?"
    }
  }
}
