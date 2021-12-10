// Copyright © 2021 Brad Howes. All rights reserved.

import AVFoundation

extension AUParameterTree {
  func parameter(withAddress address: FilterParameterAddress) -> AUParameter? {
    parameter(withAddress: address.rawValue)
  }

  public class func createParameter(withIdentifier identifier: String, name: String, address: FilterParameterAddress,
                                    min: AUValue, max: AUValue, unit: AudioUnitParameterUnit, unitName: String? = nil,
                                    flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable, .flag_CanRamp],
                                    valueStrings: [String]? = nil, dependentParameters: [NSNumber]? = nil) -> AUParameter
  {
    createParameter(withIdentifier: identifier, name: name, address: address.rawValue,
                    min: min, max: max,
                    unit: unit, unitName: unitName, flags: flags, valueStrings: valueStrings,
                    dependentParameters: dependentParameters)
  }
}
