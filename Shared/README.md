# Shared Directory

Contains code common to both iOS and macOS AUv3 extensions, and thus files here belong to both iOS and macOS
framework targets.

- [AudioUnitParameters](AudioUnitParameters.swift) -- Contains the AUParameter definitions for the runtime AU
  parameters. There is a `FilterParameterAddress` enum at the top of this file that defines unique values for
  the parameters that the rest of the code uses to identify parameter types. There is also functionality to
  generate formatted strings from parameter values.

- [FilterAudioUnit](FilterAudioUnit.swift) -- The actual AUv3 component, derived from `AUAudioUnit` class.
  Implements presets and configures the audio unit but the actual audio processing is done in
  [Kernel/__NAME__Kernel](Kernel/__NAME__Kernel.h). For the most part, this class can remain as-is except
  for the definition of any factory defaults.

- [Kernel](Kernel) -- Contains the files involved in audio processing, the most important being the
  `__NAME__Kernel.h` file.

- [User Interface](User%20Interface) -- Controller and graphical view for the filter.

- [Support](Support) -- Sundry files used elsewhere, including various class extensions.
