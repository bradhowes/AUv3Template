# About

Contains code common to both iOS and macOS AUv3 extensions, and thus files here belong to both iOS and macOS
framework targets.

- [AudioUnitParameters](AudioUnitParameters.swift) -- Contains the AUParameter definitions for the runtime AU parameters.

- [FilterAudioUnit](FilterAudioUnit.swift) -- The actual AUv3 component, derived from `AUAudioUnit` class. Implements presets and
  configures the audio unit but the actual audio processing is done in [Kernel/FilterDSPKernel](Kernel/FilterDSPKernel.hpp).

- [Kernel](Kernel) -- Contains the files involved in audio filtering.

- [User Interface](User%20Interface) -- Controller and graphical view that shows the filter settings and its frequency response
  curve.

- [Support](Support) -- Sundry files used elsewhere, including various class extensions.
