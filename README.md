![CI](https://github.com/bradhowes/__NAME__/workflows/CI/badge.svg?branch=main)

![](macOS/App/Assets.xcassets/AppIcon.appiconset/256px.png)

# About AUv3Temlate

This is full-featured AUv3 effect template for both iOS and macOS platforms. When configured, it will build an
app for each platform and embed in the app an app extension containing the AUv3 component. The apps are designed
to load the component and use it to demonstrate how it works by playing a sample audio file and routing it
through the effect.

Additional features and info:

* uses an Objective-C++ kernel for audio sample manipulation in the render thread
* provides a *very* tiny Objective-C interface to the kernel for access with Swift
* uses Swift all UI and all audio unit work not associated with rendering

The code was developed in Xcode 12.4 on macOS 11.2.1. I have tested on both macOS and iOS devices primarily in
GarageBand, but also using test hosts on both devices as well as the excellent
[AUM](https://apps.apple.com/us/app/aum-audio-mixer/id1055636344) app on iOS.

Finally, it passes all
[auval](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitProgrammingGuide/AudioUnitDevelopmentFundamentals/AudioUnitDevelopmentFundamentals.html)
tests. (`auval -v aufx flng BRay`)

# Building a new AUv3

Use the Python3 script `build.py` to create a new project derived from the template. It takes one argument, the
name of the new project:

```
% python3 build.py MyEffect
```

It creates new folder called `../MyEffect` and populates it with the files from the template. Afterwards you
should have a working AUv3 effect and delivery apps. To successfully compile you will need to edit
`Configuration/Common.xcconfig` and change `DEVELOPMENT_TEAM` to your Apple developer account so you can sign
the binaries.

> :warning: You are free to use the code according to [LICENSE.md](LICENSE.MD), but you must not replicate
> someone elses UI, icons, samples, or any other assets if you are going to distribute your effect on the App
> Store.

# App Targets

The macOS and iOS apps are simple hosts that demonstrate the functionality of the AUv3 component. In the AUv3 world,
an app serves as a delivery mechanism for an app extension like AUv3. When the app is installed, the operating system will
also install and register any app extensions found in the app.

The apps attempt to instantiate the AUv3 component and wire it up to an audio file player and the output
speaker. When it runs, you can play the sample file and manipulate the effects settings in the components UI.

# Code Layout

Each OS ([macOS](macOS) and [iOS](iOS)) have the same code layout:

* `App` -- code and configury for the application that hosts the AUv3 app extension
* `Extension` -- code and configury for the extension itself. It also contains the OS-specific UI layout
  definitions, but the controller for the UI is found in
  [Shared/User Interface/FilterViewController.swift](Shared/User%20Interface/FilterViewController.swift)
* `Framework` -- code configury for the framework that contains the shared code

The [Shared](Shared) folder holds all of the code that is used by the above products. In it you will find

* [FilterDSPKernel](Shared/Kernel/FilterDSPKernel.h) -- C++ class that does the rendering of audio samples
* [FilterAudioUnit](Shared/FilterAudioUnit.swift) -- the actual AUv3 AudioUnit written in Swift.
* [FilterViewController](Shared/User%20Interface/FilterViewController.swift) -- a custom view controller that
works with both UIView and NSView views to show the effect's controls.

Additional supporting files can be found in [Support](Shared/Support).
