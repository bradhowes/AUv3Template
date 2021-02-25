# About

This holds the three directories that define the build artifacts for macOS. There is a matching set in the [iOS](../iOS)
folder.

* [App](App) — the executable that runs and as a side-effect installs the AUv3 app extension onto the macOS device
* [Extension](Extension) — the AUv3 app extension that is packaged with the application
* [Framework](Framework) — the OS-specific framework which contains code that is shared between macOS and iOS and between the
  App and the Extension components. This folder only contains a stub file with the versioning information for
  the framework. All of the source files are found in the [Shared](../Shared) folder.
