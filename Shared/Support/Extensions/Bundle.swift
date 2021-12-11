// Copyright © 2020 Apple. All rights reserved.

import Foundation

public extension Bundle {
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

  var auBaseName: String { info(for: "AU_BASE_NAME") }
  var auComponentName: String { info(for: "AU_COMPONENT_NAME") }
  var auComponentType: String { info(for: "AU_COMPONENT_TYPE") }
  var auComponentSubtype: String { info(for: "AU_COMPONENT_SUBTYPE") }
  var auComponentManufacturer: String { info(for: "AU_COMPONENT_MANUFACTURER") }
  var auFactoryFunction: String { info(for: "AU_FACTORY_FUNCTION") }
  var appStoreId: String { info(for: "APP_STORE_ID") }
}
