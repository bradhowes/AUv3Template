// Copyright © 2021 Brad Howes. All rights reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var playMenuItem: NSMenuItem!
  @IBOutlet var bypassMenuItem: NSMenuItem!
  @IBOutlet var savePresetMenuItem: NSMenuItem!

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

  var appStoreUrl: URL {
    let appStoreId = Bundle.main.appStoreId
    return URL(string: "https://itunes.apple.com/app/id\(appStoreId)")!
  }

  func visitAppStore() {
    NSWorkspace.shared.open(appStoreUrl)
  }
}
