// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit
import AUv3Support
import AUv3Support_iOS
import os.log

@main
final class AppDelegate: AUv3Support_iOS.AppDelegate {
  // NOTE: this special form sets the subsystem name and must run before any other logger calls.
  private let log: OSLog = Shared.logger(Bundle.main.auBaseName + "Host", "AppDelegate")
}
