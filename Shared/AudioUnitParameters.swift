// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import os

/**
 Address definitions for AUParameter settings.
 */
@objc public enum FilterParameterAddress: UInt64, CaseIterable {
  case depth = 0
  case rate
  case delay
  case feedback
  case dryMix
  case wetMix
}

private extension Array where Element == AUParameter {
  subscript(index: FilterParameterAddress) -> AUParameter { self[Int(index.rawValue)] }
}

/**
 Definitions for the runtime parameters of the filter.
 */
public final class AudioUnitParameters: NSObject {
  private let log = Logging.logger("FilterParameters")

  public static let maxDelayMilliseconds: AUValue = 15.0

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

  /// AUParameterTree created with the parameter definitions for the audio unit
  public let parameterTree: AUParameterTree

  public var depth: AUParameter { parameters[.depth] }
  public var rate: AUParameter { parameters[.rate] }
  public var delay: AUParameter { parameters[.delay] }
  public var feedback: AUParameter { parameters[.feedback] }
  public var dryMix: AUParameter { parameters[.dryMix] }
  public var wetMix: AUParameter { parameters[.wetMix] }

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
  subscript(address: FilterParameterAddress) -> AUParameter { parameters[address] }

  func valueFormatter(_ address: FilterParameterAddress) -> (AUValue) -> String {
    let unitName = self[address].unitName ?? ""

    let separator: String = {
      switch address {
      case .rate, .delay: return " "
      default: return ""
      }
    }()

    let format: String = formatting(address)

    return { value in String(format: format, value) + separator + unitName }
  }

  func formatValue(_ address: FilterParameterAddress?, value: AUValue) -> String {
    guard let address = address else { return "?" }
    let format = formatting(address)
    return String(format: format, value)
  }

  /**
   Accept new values for the filter settings. Uses the AUParameterTree framework for communicating the changes to the
   AudioUnit.
   */
  func setValues(_ preset: FilterPreset) {
    depth.value = preset.depth
    rate.value = preset.rate
    delay.value = preset.delay
    feedback.value = preset.feedback
    dryMix.value = preset.dryMix
    wetMix.value = preset.wetMix
  }
}

extension AudioUnitParameters {
  private func formatting(_ address: FilterParameterAddress) -> String {
    switch address {
    case .depth, .feedback: return "%.2f"
    case .rate: return "%.2f"
    case .delay: return "%.2f"
    case .dryMix, .wetMix: return "%.0f"
    default: return "?"
    }
  }
}
