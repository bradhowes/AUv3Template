![CI](https://github.com/bradhowes/__NAME__/workflows/CI/badge.svg?branch=main)

![](macOS/App/Assets.xcassets/AppIcon.appiconset/256px.png)

# About __NAME__

This is an AUv3 audio effect that creates the iconic "flanging" effect on an audio input. It runs on both macOS
and iOS. Each OS has its own app which is used to install app extension that is the AUv3 audio effect. This is
similar in execution to that of my earlier effect [SimplyLowPass](https://github.com/bradhowes/LPF). In short,
__NAME__:

* uses an Objective-C/C++ kernel for audio sample manipulation in the render thread
* provides a very tiny Objective-C interface to the kernel for access in Swift
* performs in Swift all UI and most audio unit work not associated with rendering

The code was developed in Xcode 12.4 on macOS 11.2.1. I have tested on both macOS and iOS devices primarily in
GarageBand, but also using test hosts on both devices as well as the excellent
[AUM](https://apps.apple.com/us/app/aum-audio-mixer/id1055636344) app on iOS.

Finally, it passes all
[auval](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitProgrammingGuide/AudioUnitDevelopmentFundamentals/AudioUnitDevelopmentFundamentals.html)
tests. (`auval -v aufx flng BRay`)

## Demo Targets

The macOS and iOS apps are simple hosts that demonstrate the functionality of the AUv3 component. In the AUv3 world,
an app serves as a delivery mechanism for an app extension like AUv3. When the app is installed, the operating system will
also install and register any app extensions found in the app.

The `__NAME__` apps attempt to instantiate the AUv3 component and wire it up to an audio file player and the output speaker.
When it runs, you can play the sample file and manipulate the filter settings -- cutoff frequency in the horizontal direction and
resonance in the vertical. You can control these settings either by touching on the graph and moving the point or by using the sliders
to change their associated values. The sliders are somewhat superfluous but they act on the AUv3 component via the AUPropertyTree much
like an external MIDI controller might do.

## Code Layout

Each OS ([macOS](macOS) and [iOS](iOS)) have the same code layout:

* `App` -- code and configury for the application that hosts the AUv3 app extension
* `Extension` -- code and configury for the extension itself
* `Framework` -- code configury for the framework that contains the shared code by the app and the extension

The [Shared](Shared) folder holds all of the code that is used by the above products. In it you will find

* [DelayBuffer](Shared/Kernel/DelayBuffer.h) -- simple C++ class that holds the samples in a circular buffer
* [LFO](Shared/Kernel/LFO.h) -- simple low-frequency oscillator that varies the delay amount
* [FilterDSPKernel](Shared/Kernel/FilterDSPKernel.h) -- another C++ class that does the rendering of audio samples by sending them through the filter.
* [FilterAudioUnit](Shared/FilterAudioUnit.swift) -- the actual AUv3 AudioUnit written in Swift.
* [FilterViewController](Shared/User%20Interface/FilterViewController.swift) -- a custom view controller that
works with both UIView and NSView views to show the effect's controls.

Additional supporting files can be found in [Support](Shared/Support).
