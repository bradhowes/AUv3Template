# Support

Collection of additional utilities that make life easier when working with AUv3 and Swift.

- [AudioUnitManager](AudioUnitManager.swift) -- mimics a very minimal AUv3 host by instantiating the AUv3 plugin
  and showing its view. Unfortunately, the way that macOS and iOS work with AUv3 instantiation differs, so there
  is a small bit of `#if os(*)` noise. And unfortunately, it sometimes must fall back to instantiating the
  `FilterViewController`.

- [Logging](Logging.swift) -- implements my own way of partitioning log statements

- [Audio](Audio) -- holds an audio file that is used by the app to demonstrate the AUv3 effect. Also contains
  [SimplePlayEngine](Audio/SimplePlayEngine.swift) (based on Apple code) that creates a simple audio graph
  consisting of an `AVAudioPlayerNode` that plays the sample file and the AUv3 effect node, with the sample
  audio going into the effect and the effect connected to device's audio output.

- [Class Extensions](Class%20Extensions) -- useful extensions to various Apple classes to simply the code
