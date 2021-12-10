// Copyright © 2021 Brad Howes. All rights reserved.

import AppKit

public enum AppStore {
  static var appStoreUrl: URL {
    let appStoreId = Bundle.main.appStoreId
    return URL(string: "https://itunes.apple.com/app/id\(appStoreId)")!
  }

  static var reviewUrl: URL {
    let appStoreId = Bundle.main.appStoreId
    return URL(string: "https://itunes.apple.com/app/id\(appStoreId)?action=write-review")!
  }

  static var supportUrl: URL {
    return URL(string: "https://github.com/bradhowes/__NAME__")!
  }

  static func visitAppStore() {
    NSWorkspace.shared.open(appStoreUrl)
  }

  static func reviewApp() {
    NSWorkspace.shared.open(reviewUrl)
  }

  static func visitSupportUrl() {
    NSWorkspace.shared.open(supportUrl)
  }
}
