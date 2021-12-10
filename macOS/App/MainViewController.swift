// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import Cocoa

final class MainViewController: NSViewController {

  private let audioUnitHost = AudioUnitHost(componentDescription: FilterAudioUnit.componentDescription)
  internal var userPresetsManager: UserPresetsManager?

  private var playButton: NSButton!
  private var bypassButton: NSButton!
  private var presetsButton: NSButton!

  private var presetsMenu: NSMenu!
  private var savePresetMenuItem: NSMenuItem!
  private var renamePresetMenuItem: NSMenuItem!
  private var deletePresetMenuItem: NSMenuItem!

  private var playMenuItem: NSMenuItem!
  private var bypassMenuItem: NSMenuItem!

  @IBOutlet var containerView: NSView!
  @IBOutlet var loadingText: NSTextField!

  private var windowController: MainWindowController? { view.window?.windowController as? MainWindowController }
  private var appDelegate: AppDelegate? { NSApplication.shared.delegate as? AppDelegate }

  private var filterView: NSView?
  private var parameterObserverToken: AUParameterObserverToken?
}

// MARK: - View Management

extension MainViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    audioUnitHost.delegate = self
  }

  override func viewWillAppear() {
    super.viewWillAppear()

    guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { fatalError() }
    presetsMenu = appDelegate.presetsMenu
    guard presetsMenu != nil else { fatalError() }
    presetsMenu.autoenablesItems = false

    savePresetMenuItem = appDelegate.savePresetMenuItem
    savePresetMenuItem.target = self
    savePresetMenuItem.action = #selector(handleSavePresetMenuSelected(_:))

    renamePresetMenuItem = appDelegate.renamePresetMenuItem
    renamePresetMenuItem.target = self
    renamePresetMenuItem.action = #selector(handleRenamePresetMenuSelected(_:))

    deletePresetMenuItem = appDelegate.deletePresetMenuItem
    deletePresetMenuItem.target = self
    deletePresetMenuItem.action = #selector(handleDeletePresetMenuSelected(_:))

    playMenuItem = appDelegate.playMenuItem
    bypassMenuItem = appDelegate.bypassMenuItem
    guard playMenuItem != nil, bypassMenuItem != nil else { fatalError() }
    bypassMenuItem.isEnabled = false

    guard let windowController = view.window?.windowController as? MainWindowController else { fatalError() }
    view.window?.delegate = self

    playButton = windowController.playButton
    bypassButton = windowController.bypassButton
    bypassButton.isEnabled = false
    presetsButton = windowController.presetsButton

    guard let savePresetMenuItem = appDelegate.savePresetMenuItem else { fatalError() }
    savePresetMenuItem.target = self
    savePresetMenuItem.action = #selector(handleSavePresetMenuSelected(_:))

    // Keep last
    audioUnitHost.delegate = self
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    filterView?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: containerView.frame.size)
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    let showedAlertKey = "showedInitialAlert"
    guard UserDefaults.standard.bool(forKey: showedAlertKey) == false else { return }
    UserDefaults.standard.set(true, forKey: showedAlertKey)
    let alert = NSAlert()
    alert.alertStyle = .informational
    alert.messageText = "AUv3 Component Installed"
    alert.informativeText =
      """
      The AUv3 component '__NAME__' is now available on your device and can be used in other AUv3 host apps such as GarageBand and Logic.

      You can continue to use this app to experiment, but you do not need to have it running to access the AUv3 component in other apps.

      However, if you later delete this app from your device, the AUv3 component will no longer be available in other host apps.
      """
    alert.addButton(withTitle: "OK")
    alert.beginSheetModal(for: view.window!) { _ in }
  }
}

extension MainViewController: AudioUnitHostDelegate {

  func connected(audioUnit: AUAudioUnit, viewController: ViewController) {
    userPresetsManager = .init(for: audioUnit)
    connectFilterView(viewController)
  }

  func failed(error: AudioUnitHostError) {

  }

  private func connectFilterView(_ viewController: NSViewController) {
    guard let viewController = audioUnitHost.viewController else { fatalError() }
    let filterView = viewController.view
    containerView.addSubview(filterView)
    filterView.pinToSuperviewEdges()
    self.filterView = filterView

    addChild(viewController)
    view.needsLayout = true
    containerView.needsLayout = true
  }
}

extension MainViewController {

  @IBAction private func togglePlay(_ sender: NSButton) {
    let isPlaying = audioUnitHost.isPlaying

    playButton?.image = isPlaying ? NSImage(named: "stop") : NSImage(named: "play")

    audioUnitHost.audioUnit?.shouldBypassEffect = false
    bypassButton?.image = NSImage(named: "enabled")
    bypassButton?.isEnabled = isPlaying
    bypassMenuItem?.isEnabled = isPlaying
  }

  @IBAction private func toggleBypass(_ sender: NSButton) {
    let wasBypassed = audioUnitHost.audioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    audioUnitHost.audioUnit?.shouldBypassEffect = isBypassed
    bypassButton?.image = isBypassed ? NSImage(named: "bypassed") : NSImage(named: "enabled")
    bypassMenuItem?.title = isBypassed ? "Resume" : "Bypass"
  }

  @IBAction private func presetsButton(_ sender: NSButton) {
    let location = NSPoint(x: 0, y: sender.frame.height + 5)
    presetsMenu.popUp(positioning: nil, at: location, in: sender)
  }

  @objc private func handleSavePresetMenuSelected(_ sender: NSMenuItem) throws {
    SavePresetAction(self).start(sender)
    updatePresetMenu()
  }

  @objc private func handleRenamePresetMenuSelected(_ sender: NSMenuItem) throws {
    RenamePresetAction(self).start(sender)
    updatePresetMenu()
  }

  @objc private func handleDeletePresetMenuSelected(_ sender: NSMenuItem) throws {
    DeletePresetAction(self).start(sender)
    updatePresetMenu()
  }

  @objc private func presetMenuItemSelected(_ sender: NSMenuItem) {
    guard let userPresetsManager = userPresetsManager else { return }
    let number = tagToNumber(sender.tag)
    userPresetsManager.makeCurrentPreset(number: number)
    updatePresetMenu()
  }
}

extension MainViewController: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    audioUnitHost.cleanup()
    guard let parameterTree = audioUnitHost.audioUnit?.parameterTree,
          let parameterObserverToken = parameterObserverToken else { return }
    parameterTree.removeParameterObserver(parameterObserverToken)
  }
}

extension MainViewController {

  private func numberToTag(_ number: Int) -> Int {
    number >= 0 ? (number + 10000) : number
  }

  private func tagToNumber(_ tag: Int) -> Int {
    tag >= 10000 ? (tag - 10000) : tag
  }

  private func populatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }
    let audioUnit = userPresetsManager.audioUnit

    for preset in audioUnit.factoryPresetsArray {
      let key = "\(preset.number + 1)"
      let menuItem = NSMenuItem(title: preset.name, action: #selector(presetMenuItemSelected(_:)), keyEquivalent: key)
      menuItem.tag = numberToTag(preset.number)
      presetsMenu.addItem(menuItem)
    }

    updatePresetMenu()
  }

  internal func updatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }
    let active = userPresetsManager.audioUnit.currentPreset?.number ?? Int.max

    savePresetMenuItem.isEnabled = true
    renamePresetMenuItem.isEnabled = active < 0
    deletePresetMenuItem.isEnabled = active < 0

    // Determine number of items to keep: 3 commands + divider + # of factory items
    let factoryCount = userPresetsManager.audioUnit.factoryPresetsArray.count
    let stockCount = 3 + 1 + factoryCount
    presetsMenu.items = presetsMenu.items.dropLast(presetsMenu.items.count - stockCount)

    if factoryCount > 0, !userPresetsManager.presets.isEmpty {
      presetsMenu.addItem(.separator())
    }

    for preset in userPresetsManager.presetsOrderedByName {
      let key = ""
      let menuItem = NSMenuItem(title: preset.name, action: #selector(presetMenuItemSelected(_:)), keyEquivalent: key)
      menuItem.tag = numberToTag(preset.number)
      presetsMenu.addItem(menuItem)
    }

    // Finally checkmark any item that matches the current preset
    for (index, item) in presetsMenu.items.enumerated() {
      item.state = (index > 3 && tagToNumber(item.tag) == active) ? .on : .off
    }
  }
}

extension MainViewController {
  func notify(_ title: String, message: String) {
    let alert = NSAlert()
    alert.alertStyle = .informational
    alert.messageText = title
    alert.informativeText = message

    alert.addButton(withTitle: "OK")
    alert.beginSheetModal(for: view.window!) { _ in }
    alert.runModal()
  }

  func yesOrNo(_ title: String, message: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
  }
}
