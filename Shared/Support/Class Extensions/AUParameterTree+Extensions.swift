// Copyright © 2021 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameterTree {
    func parameter(withAddress address: FilterParameterAddress) -> AUParameter? {
        parameter(withAddress: address.rawValue)
    }

    class func createParameter(withIdentifier identifier: String, name: String, address: FilterParameterAddress,
                               min: AUValue, max: AUValue, unit: AudioUnitParameterUnit, unitName: String? = nil,
                               flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable],
                               valueStrings: [String]? = nil, dependentParameters: [NSNumber]? = nil) -> AUParameter {
        let param = createParameter(withIdentifier: identifier, name: name, address: address.rawValue,
                                    min: min, max: max,
                                    unit: unit, unitName: unitName, flags: flags, valueStrings: valueStrings,
                                    dependentParameters: dependentParameters)
        return param
    }
}
