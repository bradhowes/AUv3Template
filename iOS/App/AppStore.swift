// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit

/**
 Collection of attributes and functions involving the App Store entry for the app.
 */
public enum AppStore {

  static let urlBase = "https://itunes.apple.com/app/id"

  /// The URL for the app in the App Store
  static var appStoreUrl: URL { .init(string: urlBase + Bundle.main.appStoreId)! }

  /// The URL to post a review in the App Store
  static var reviewUrl: URL { .init(string: urlBase + Bundle.main.appStoreId + "?action=write-review")! }

  /// The support URL for the app
  static var supportUrl: URL { return URL(string: "https://github.com/bradhowes/__NAME__")! }

  /// Open a web view to show the App Store entry for the app
  static func visitAppStore() { UIApplication.shared.open(appStoreUrl, options: [:], completionHandler: nil) }

  /// Open a web view to show the review page in the App Store
  static func reviewApp() { UIApplication.shared.open(reviewUrl, options: [:], completionHandler: nil) }

  /// Open a web view to show the support page for the app
  static func visitSupportUrl() { UIApplication.shared.open(supportUrl, options: [:], completionHandler: nil) }
}
