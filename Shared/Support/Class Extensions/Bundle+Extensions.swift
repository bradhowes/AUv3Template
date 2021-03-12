// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

extension Bundle {

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
    public var releaseVersionNumber: String { info(for: "CFBundleShortVersionString") }

    /// Obtain the build version number associated with the bundle or "" if none found
    public var buildVersionNumber: String { info(for: "CFBundleVersion") }

    /// Obtain the bundle identifier or "" if there is not one
    public var bundleID: String { Bundle.main.bundleIdentifier?.lowercased() ?? "" }

    /// Obtain the build scheme that was used to generate the bundle. Returns " Dev" or " Staging" or ""
    public var scheme: String {
        if bundleID.contains(".dev") { return " Dev" }
        if bundleID.contains(".staging") { return " Staging" }
        return ""
    }

    /// Obtain a version string with the following format: "Version V.B[ S]"
    /// where V is the releaseVersionNumber, B is the buildVersionNumber and S is the scheme.
    public var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(scheme)" }

    public var auBaseName: String { info(for: "AU_BASE_NAME") }
    public var auComponentName: String { info(for: "AU_COMPONENT_NAME") }
    public var auComponentTypeString: String { info(for: "AU_COMPONENT_TYPE") }
    public var auComponentSubtypeString: String { info(for: "AU_COMPONENT_SUBTYPE") }
    public var auComponentManufacturerString: String { info(for: "AU_COMPONENT_MANUFACTURER") }
    public var auComponentType: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_TYPE")) }
    public var auComponentSubtype: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_SUBTYPE")) }
    public var auComponentManufacturer: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_MANUFACTURER")) }
    public var auExtensionName: String { auBaseName + "AU.appex" }
    public var auExtensionUrl: URL? { builtInPlugInsURL?.appendingPathComponent(auExtensionName) }
    public var appStoreId: String { info(for: "APP_STORE_ID") }
}
