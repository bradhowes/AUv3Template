// Copyright © 2022 Brad Howes. All rights reserved.

import Cocoa
import AUv3Support

/**
 The app delegate for the host application.
 */
@main
class AppDelegate: NSObject, NSApplicationDelegate {

  // NOTE: this special form sets the subsystem name and must run before any other logger calls.
  private let log = Shared.logger(Bundle.main.auBaseName + "Host", "AppDelegate")

  @IBOutlet weak var playMenuItem: NSMenuItem!
  @IBOutlet weak var bypassMenuItem: NSMenuItem!
  @IBOutlet weak var presetsMenu: NSMenu!

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

  var appStoreUrl: URL {
    let appStoreId = Bundle.main.appStoreId
    return URL(string: "https://itunes.apple.com/app/id\(appStoreId)")!
  }

  func visitAppStore() {
    NSWorkspace.shared.open(appStoreUrl)
  }
}
