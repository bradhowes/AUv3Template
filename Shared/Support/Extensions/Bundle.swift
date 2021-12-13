// Copyright © 2020 Apple. All rights reserved.

import Foundation

public extension Bundle {

  static var shared: Bundle { Bundle(for: FilterAudioUnit.self) }

  /// Component description that matches this AudioUnit. The values must match those found in the Info.plist
  /// Used by the app hosts to load the right component.
  var componentDescription: AudioComponentDescription {
    AudioComponentDescription(
      componentType: FourCharCode(stringLiteral: auComponentType),
      componentSubType: FourCharCode(stringLiteral: auComponentSubtype),
      componentManufacturer: FourCharCode(stringLiteral: auComponentManufacturer),
      componentFlags: 0,
      componentFlagsMask: 0
    )
  }

  /**
   Attempt to get a String value from the Bundle meta dictionary.

   - parameter key: what to fetch
   - returns: the value found or an empty string
   */
  private func info(for key: String) -> String {
    guard let dict = infoDictionary else { return "" }
    guard let value = dict[key] as? String else { return "" }
    return value
  }

  /// Obtain the release version number associated with the bundle or "" if none found
  var releaseVersionNumber: String { info(for: "CFBundleShortVersionString") }

  /// Obtain the build version number associated with the bundle or "" if none found
  var buildVersionNumber: String { info(for: "CFBundleVersion") }

  /// Obtain the bundle identifier or "" if there is not one
  static var bundleID: String { Bundle.main.bundleIdentifier ?? "" }

  /// Obtain the build scheme that was used to generate the bundle. Returns " Dev" or " Staging" or ""
  static var scheme: String {
    if bundleID.lowercased().contains(".dev") { return " Dev" }
    if bundleID.lowercased().contains(".staging") { return " Staging" }
    return ""
  }

  /// Obtain a version string with the following format: "Version V.B[ S]"
  /// where V is the releaseVersionNumber, B is the buildVersionNumber and S is the scheme.
  var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(Self.scheme)" }

  /// THe name of the audio unit. See also `auComponentName`
  var auBaseName: String { info(for: "AU_BASE_NAME") }

  /// The combination of `auComponentManufacturer` and `auBaseName`
  var auComponentName: String { info(for: "AU_COMPONENT_NAME") }

  /// The type of audio unit the component represents (musical instrument or effect)
  var auComponentType: String { info(for: "AU_COMPONENT_TYPE") }

  /// The subtype of the audio unit.
  var auComponentSubtype: String { info(for: "AU_COMPONENT_SUBTYPE") }

  /// The ID of the component manufacturer
  var auComponentManufacturer: String { info(for: "AU_COMPONENT_MANUFACTURER") }

  /// The function to invoke to create the AUv3 audio unit.
  var auFactoryFunction: String { info(for: "AU_FACTORY_FUNCTION") }

  /// The unique App Store ID for this component
  var appStoreId: String { info(for: "APP_STORE_ID") }
}
