// Copyright © 2021 Brad Howes. All rights reserved.

#if os(macOS)

import AUv3Support
import AUv3Support_macOS
import CoreAudioKit
import Cocoa
import AVFAudio
import os.log

/**
 Main view controller for the host app. When all UI items are available, it puts them into a config file and creates a
 new HostViewManager with it. It is this class that does all of the work.
 */
final class MainViewController: NSViewController {
  private let log = Shared.logger("MainViewController")

  @IBOutlet weak var containerView: NSView!
  @IBOutlet weak var loadingText: NSTextField!

  private var windowController: MainWindowController? { view.window?.windowController as? MainWindowController }
  private var appDelegate: AppDelegate? { NSApplication.shared.delegate as? AppDelegate }

  private var hostViewManager: HostViewManager?
  private var windowObserver: NSKeyValueObservation?
}

extension MainViewController {

  func makeHostViewManager() {
    guard let appDelegate = appDelegate,
          appDelegate.presetsMenu != nil,
          let windowController = windowController
    else {
      fatalError()
    }

    let bundle = Bundle.main
    let audioUnitName = bundle.auBaseName
    let componentDescription = AudioComponentDescription(componentType: bundle.auComponentType,
                                                         componentSubType: bundle.auComponentSubtype,
                                                         componentManufacturer: bundle.auComponentManufacturer,
                                                         componentFlags: 0, componentFlagsMask: 0)
    let config = HostViewConfig(componentName: audioUnitName,
                                componentDescription: componentDescription,
                                sampleLoop: .sample1,
                                playButton: windowController.playButton,
                                bypassButton: windowController.bypassButton,
                                presetsButton: windowController.presetsButton,
                                playMenuItem: appDelegate.playMenuItem,
                                bypassMenuItem: appDelegate.bypassMenuItem,
                                presetsMenu: appDelegate.presetsMenu,
                                viewController: self, containerView: containerView)
    hostViewManager = .init(config: config)
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    makeHostViewManager()
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    hostViewManager?.showInitialPrompt()
  }
}

#endif
