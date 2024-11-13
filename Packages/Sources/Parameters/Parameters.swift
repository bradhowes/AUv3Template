// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import CoreAudioKit
import Foundation
import ParameterAddress
import os.log

private extension Array where Element == AUParameter {
  subscript(index: ParameterAddress) -> AUParameter { self[Int(index.rawValue)] }
}

/**
 Definitions for the runtime parameters of the filter.
 */
public final class Parameters: NSObject, ParameterSource {

  private let log = Shared.logger("AudioUnitParameters")

  /// Array of AUParameter entities created from ParameterAddress value definitions.
  public let parameters: [AUParameter] = ParameterAddress.allCases.map { $0.parameterDefinition.parameter }

  /// Array of 2-tuple values that pair a factory preset name and its definition
  public let factoryPresetValues: [(name: String, preset: Configuration)] = [
    ("Flangie",
     .init(depth: 7, rate: 0.07, delay: 0.0, feedback: 50, dry: 50, wet: 50, negativeFeedback: 0, odd90: 0)),
    ("Sweeper",
     .init(depth: 15, rate: 0.6, delay: 0.14, feedback: 50, dry: 50, wet: 50, negativeFeedback: 0, odd90: 0)),
    ("Chorious",
     .init(depth: 20, rate: 0.3, delay: 0.15, feedback: 50, dry: 50, wet: 50, negativeFeedback: 0, odd90:1)),
    ("Lord Tremolo",
     .init(depth: 5, rate: 8.0, delay: 0.0, feedback: 85, dry: 0, wet: 100, negativeFeedback: 0, odd90:0)),
    ("Wide Flangie",
     .init(depth: 100, rate: 0.14, delay: 0.72, feedback: 50, dry: 50, wet: 50, negativeFeedback: 0, odd90: 1)),
    ("Wide Sweeper",
     .init(depth: 100, rate: 0.14, delay: 1.51, feedback: 80, dry: 50, wet: 50, negativeFeedback: 0, odd90: 1)),
  ]

  /// Array of `AUAudioUnitPreset` for the factory presets.
  public var factoryPresets: [AUAudioUnitPreset] {
    factoryPresetValues.enumerated().map { .init(number: $0.0, name: $0.1.name ) }
  }

  /// AUParameterTree created with the parameter definitions for the audio unit
  public let parameterTree: AUParameterTree

  /// Obtain the parameter setting that determines how much variation in time there is when reading values from
  /// the delay buffer.
  public var depth: AUParameter { parameters[.depth] }
  /// Obtain the parameter setting that determines how fast the LFO operates
  public var rate: AUParameter { parameters[.rate] }
  /// Obtain the parameter setting that determines the minimum delay applied incoming samples. The actual delay value is
  /// this value plus the `depth` times the current LFO value.
  public var delay: AUParameter { parameters[.delay] }
  /// Obtain the parameter setting that determines how much of the processed signal is added to the 
  public var feedback: AUParameter { parameters[.feedback] }
  /// Obtain the `depth` parameter setting
  public var dryMix: AUParameter { parameters[.dry] }
  /// Obtain the `depth` parameter setting
  public var wetMix: AUParameter { parameters[.wet] }
  /// Obtain the `depth` parameter setting
  public var negativeFeedback: AUParameter { parameters[.negativeFeedback] }
  /// Obtain the `depth` parameter setting
  public var odd90: AUParameter { parameters[.odd90] }

  /**
   Create a new AUParameterTree for the defined filter parameters.
   */
  override public init() {
    parameterTree = AUParameterTree.createTree(withChildren: parameters)
    super.init()
    installParameterValueFormatter()
  }
}

extension Parameters {

  private var missingParameter: AUParameter { fatalError() }

  /// Apply a factory preset -- user preset changes are handled by changing AUParameter values through the audio unit's
  /// `fullState` attribute.
  public func useFactoryPreset(_ preset: AUAudioUnitPreset) {
    if preset.number >= 0 {
      setValues(factoryPresetValues[preset.number].preset)
    }
  }

  public subscript(address: ParameterAddress) -> AUParameter {
    parameterTree.parameter(withAddress: address.parameterAddress) ?? missingParameter
  }

  private func installParameterValueFormatter() {
    parameterTree.implementorStringFromValueCallback = { param, valuePtr in
      let value: AUValue
      if let valuePtr = valuePtr {
        value = valuePtr.pointee
      } else {
        value = param.value
      }
      return String(format: param.stringFormatForValue, value) + param.suffix
    }
  }

  /**
   Accept new values for the filter settings. Uses the AUParameterTree framework for communicating the changes to the
   AudioUnit.
   */
  public func setValues(_ preset: Configuration) {
    depth.value = preset.depth
    rate.value = preset.rate
    delay.value = preset.delay
    feedback.value = preset.feedback
    dryMix.value = preset.dry
    wetMix.value = preset.wet
    negativeFeedback.value = preset.negativeFeedback
    odd90.value = preset.odd90
  }
}

extension AUParameter: AUParameterFormatting {

  /// Obtain string to use to separate a formatted value from its units name
  public var unitSeparator: String {
    switch parameterAddress {
    case .depth, .rate, .delay: return " "
    default: return ""
    }
  }

  /// Obtain the suffix to apply to a formatted value
  public var suffix: String { makeFormattingSuffix(from: unitName) }

  /// Obtain the format to use in String(format:value) when formatting a values
  var stringFormatForValue: String {
    switch parameterAddress {
    case .dry, .wet: return "%.0f"
    default: return "%.2f"
    }
  }
  /// Obtain a closure that will format parameter values into a string
  public var stringFormatForDisplayValue: String {
    switch self.parameterAddress {
    case .depth, .feedback, .dry, .wet: return "%.0f"
    default: return "%.2f"
    }
  }
}
