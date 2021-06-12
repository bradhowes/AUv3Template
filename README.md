![CI](https://github.com/bradhowes/AUv3Template/workflows/CI/badge.svg?branch=main)

![](macOS/App/Assets.xcassets/AppIcon.appiconset/256px.png)

# About AUv3Template

This is full-featured AUv3 effect template for both iOS and macOS platforms. When configured, it will build an
app for each platform and embed in the app an app extension containing the AUv3 component. The apps are designed
to load the AUv3 component and use it to demonstrate how it works by playing a sample audio file and routing it
through the effect.

Additional features and info:

* Uses a C++ kernel for audio sample manipulation in the render thread
* Provides a *very* tiny Objective-C (Objective-C++) wrapper for access to the kernel in Swift
* Uses Swift for all UI and all audio unit work not associated with sample rendering

The code was developed in Xcode 12.4 on macOS 11.2.1. I have tested on both macOS and iOS devices primarily in
GarageBand, but also using test hosts on both devices as well as the excellent
[AUM](https://apps.apple.com/us/app/aum-audio-mixer/id1055636344) app on iOS.

Finally, it passes all
[auval](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitProgrammingGuide/AudioUnitDevelopmentFundamentals/AudioUnitDevelopmentFundamentals.html)
tests:

```
% auval -v aufx flng BRay
```

Here `flng` is the unique component subtype for my [SimplyFlange](https://github.com/bradhowes/SimplyFlange)
effect and `BRay` is my own manufacturer ID. You should use your own values that you put in
[Configuration/Common.xcconfig](Configuration/Common.xcconfig).

# Generating a new AUv3 Project

Since this is a template, use the [build.py](build.py) Python3 script to create a new project from it. It takes
two arguments, the name of the new project and the _subtype_ of the effect:

```
% python3 build.py MyEffect subtype
```

The name value should be self-evident in purpose; the _subtype_ is a unique 4-character identifier for your new
effect. It should be unique at least for your manufacturer space (see
[Configuration/Common.xcconfig](Configuration/Common.xcconfig))

The script will creates new folder called `../MyEffect` and populate it with the files from this template.
Afterwards you should have a working AUv3 effect embedded in demo apps for iOS and macOS. All files with
`__NAME__` in them will be replaced with the first argument given to `build.py` (e.g. "MyEffect"), and all text
files will be changed so that the strings `__NAME__` and `__SUBTYPE__` are replaced with the values you
provided.

Note that To successfully compile you will need to edit
[Configuration/Common.xcconfig](Configuration/Common.xcconfig) and change `DEVELOPMENT_TEAM` to hold your own
Apple developer account ID so you can sign the binaries. You should also adjust other settings as well to
properly identify you and/or your company.

There are additional values in this file that you really should change, especially to remove any risk of
collision with other AUv3 effects you may have on your system.

> :warning: You are free to use the code according to [LICENSE.md](LICENSE.md), but you must not replicate
> someone's UI, icons, samples, or any other assets if you are going to distribute your effect on the App Store.

## fastlane

The project will also be setup to generate screenshots using [fastlane](https://github.com/fastlane/fastlane).
However, you will still need to *install* fastlane if you don't already have it. I used:

```
% brew install fastlane
```

but there are other (better?) ways described in the [fastlane docs](https://docs.fastlane.tools).

# App Targets

The macOS and iOS apps are simple AUv3 hosts that demonstrate the functionality of the AUv3 component. In the
AUv3 world, an app serves as a delivery mechanism for an app extension like AUv3. When the app is installed, the
operating system will also install and register any app extensions found in the app.

The apps attempt to instantiate the AUv3 component and wire it up to an audio file player and the output
speaker. When it runs, you can play the sample file and manipulate the effects settings in the components UI.

# Code Layout

Each OS ([macOS](macOS) and [iOS](iOS)) have the same code layout:

* `App` -- code and configury for the application that hosts the AUv3 app extension
* `Extension` -- code and configury for the extension itself. It also contains the OS-specific UI layout
  definitions, but the controller for the UI is found in
  [Shared/User Interface/FilterViewController.swift](Shared/User%20Interface/FilterViewController.swift)
* `Framework` -- code configury for the framework that contains the shared code

The [Shared](Shared) folder holds all of the code that is used by the above products. In it you will find the
files for the audio unit ([FilterAudioUnit](Shared/FilterAudioUnit.swift)), the user changable parameters for
the audio unit ([AudioUnitParameters](Shared/AudioUnitParameters.swift)), and the audio processing "kernel"
written in C++ ([__NAME__Kernel](Shared/Kernel/__NAME__Kernel.h)).

There are adidtional details in the individual folders as well.
