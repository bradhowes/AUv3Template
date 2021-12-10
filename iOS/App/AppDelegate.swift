// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import AVKit
import os
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  private let log = Logging.logger("AppDelegate")
  private var mainViewController: MainViewController?
  var window: UIWindow?

  func setMainViewController(_ mainViewController: MainViewController) {
    self.mainViewController = mainViewController
  }

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
  {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
    } catch let error as NSError {
      fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
    }
    let preferredSampleRate = 44100.0
    do {
      try audioSession.setPreferredSampleRate(preferredSampleRate)
    } catch let error as NSError {
      os_log(.error, log: log, "Failed to set the preferred sample rate: %{public}s",
             error.localizedDescription)
    }
    let preferredBufferSize = 512.0
    do {
      try audioSession.setPreferredIOBufferDuration(preferredBufferSize / preferredSampleRate)
    } catch let error as NSError {
      os_log(.error, log: log, "Failed to set the preferred IO buffer duration: %{public}s",
             error.localizedDescription)
    }
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    os_log(.info, log: log, "applicationWillResignActive")
    mainViewController?.stopPlaying()
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    os_log(.info, log: log, "applicationDidEnterBackground")
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    os_log(.info, log: log, "applicationWillEnterForeground")
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    os_log(.info, log: log, "applicationDidBecomeActive")
  }

  func applicationWillTerminate(_ application: UIApplication) {
    os_log(.info, log: log, "applicationWillTerminate")
    mainViewController?.stopPlaying()
  }
}
