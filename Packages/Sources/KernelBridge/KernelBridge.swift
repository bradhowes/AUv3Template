// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import Kernel

// Extend the Obj-C KernelBridge with protocols for interoperability with `FilterAudioUnit` and `AudioUnitParameters`
// classes.
extension KernelBridge: AUParameterHandler, AudioRenderer {}
