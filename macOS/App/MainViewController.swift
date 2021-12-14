// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import Cocoa

/**
 Main view controller for the app. Shows controls for the filter audio unit and manages the preset control in the window
 toolbar.
 */
final class MainViewController: NSViewController {
  private let showedInitialAlert = "showedInitialAlert"

  private var audioUnitHost: AudioUnitHost!
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

  @IBOutlet weak var instructions: NSView!
  @IBOutlet weak var instructionsButton: NSButton!

  private var windowController: MainWindowController? { view.window?.windowController as? MainWindowController }
  private var appDelegate: AppDelegate? { NSApplication.shared.delegate as? AppDelegate }

  private var filterView: NSView?
  private var allParameterValuesObserverToken: NSKeyValueObservation?
  private var parameterTreeObserverToken: AUParameterObserverToken?

}

// MARK: - View Management

extension MainViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Start out hidden and only show after everything is up and running and we discover that this is the first time
    // for the user to run the application on their device.
    instructions.isHidden = true
    instructions.wantsLayer = true
    instructions.layer?.borderWidth = 4
    instructions.layer?.borderColor = NSColor.systemOrange.lighter.cgColor
    instructions.layer?.cornerRadius = 16
    instructions.backgroundColor = NSColor.black
    instructionsButton.target = self
    instructionsButton.action = #selector(dismissInstructions(_:))

    audioUnitHost = .init(componentDescription: Bundle(for: FilterAudioUnit.self).componentDescription)
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { fatalError() }

    presetsMenu = appDelegate.presetsMenu
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
    presetsButton = windowController.presetsButton
    guard playButton != nil, bypassButton != nil, presetsButton != nil else { fatalError() }

    bypassButton.isEnabled = false

    guard let savePresetMenuItem = appDelegate.savePresetMenuItem else { fatalError() }
    savePresetMenuItem.target = self
    savePresetMenuItem.action = #selector(handleSavePresetMenuSelected(_:))

    audioUnitHost.delegate = self
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    filterView?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: containerView.frame.size)
  }
}

// MARK: - Actions

extension MainViewController {

  @IBAction func togglePlay(_ sender: NSButton) {
    audioUnitHost.togglePlayback()
    let isPlaying = audioUnitHost.isPlaying

    playButton?.image = isPlaying ? NSImage(named: "stop") : NSImage(named: "play")

    audioUnitHost.audioUnit?.shouldBypassEffect = false
    bypassButton?.image = NSImage(named: "enabled")
    bypassButton?.isEnabled = isPlaying
    bypassMenuItem?.isEnabled = isPlaying
  }

  @IBAction func toggleBypass(_ sender: NSButton) {
    let wasBypassed = audioUnitHost.audioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    audioUnitHost.audioUnit?.shouldBypassEffect = isBypassed
    bypassButton?.image = isBypassed ? NSImage(named: "bypassed") : NSImage(named: "enabled")
    bypassMenuItem?.title = isBypassed ? "Resume" : "Bypass"
  }

  @IBAction func showPresetsMenu(_ sender: NSButton) {
    let location = NSPoint(x: 0, y: sender.frame.height + 5)
    presetsMenu.popUp(positioning: nil, at: location, in: sender)
  }

  @IBAction func handleSavePresetMenuSelected(_ sender: NSMenuItem) throws {
    SavePresetAction(self, completion: self.updatePresetMenu).start(sender)
    updatePresetMenu()
  }

  @IBAction func handleRenamePresetMenuSelected(_ sender: NSMenuItem) throws {
    RenamePresetAction(self, completion: self.updatePresetMenu).start(sender)
  }

  @IBAction func handleDeletePresetMenuSelected(_ sender: NSMenuItem) throws {
    DeletePresetAction(self, completion: self.updatePresetMenu).start(sender)
    updatePresetMenu()
  }

  @IBAction func presetMenuItemSelected(_ sender: NSMenuItem) {
    guard let userPresetsManager = userPresetsManager else { return }
    let number = tagToNumber(sender.tag)
    userPresetsManager.makeCurrentPreset(number: number)
    updatePresetMenu()
  }

  @IBAction func dismissInstructions(_ sender: NSButton) {
    UserDefaults.standard.set(true, forKey: showedInitialAlert)
    instructions.isHidden = true
  }
}

// MARK: - AudioUnitHostDelegate

extension MainViewController: AudioUnitHostDelegate {

  func connected(audioUnit: AUAudioUnit, viewController: ViewController) {
    userPresetsManager = .init(for: audioUnit)
    connectFilterView(viewController)
    connectParametersToControls(audioUnit)
    showInstructions()
  }

  func failed(error: AudioUnitHostError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    DispatchQueue.performOnMain {

      // Show error to user and then exit app since there is nothing more to do
      self.notify(title: "AUv3 Failure", message: message) {
        NSApplication.shared.mainWindow?.close()
      }
    }
  }
}

// MARK: - NSWindowDelegate

extension MainViewController: NSWindowDelegate {

  func windowWillClose(_ notification: Notification) {
    audioUnitHost.cleanup()
    guard let parameterTree = audioUnitHost.audioUnit?.parameterTree,
          let parameterTreeObserverToken = parameterTreeObserverToken else { return }
    parameterTree.removeParameterObserver(parameterTreeObserverToken)
  }
}

// MARK: - Private

private extension MainViewController {

  func connectFilterView(_ viewController: NSViewController) {
    guard let viewController = audioUnitHost.viewController else { fatalError() }
    let filterView = viewController.view
    containerView.addSubview(filterView)
    filterView.pinToSuperviewEdges()
    self.filterView = filterView

    addChild(viewController)
    view.needsLayout = true
    containerView.needsLayout = true
  }

  func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    guard let parameterTree = audioUnit.parameterTree else {
      fatalError("FilterAudioUnit does not define any parameters.")
    }

    audioUnitHost.restore()
    populatePresetMenu()
    updatePresetMenu()

    allParameterValuesObserverToken = audioUnit.observe(\.allParameterValues) { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.performOnMain { self.updateView() }
    }

    parameterTreeObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.performOnMain { self.updateView() }
    })
  }

  func showInstructions() {
#if !Dev
    if UserDefaults.standard.bool(forKey: showedInitialAlert) {
      instructions.isHidden = true
      return
    }
#endif
    instructions.isHidden = false

    // Since this is the first time to run, apply the first factory preset.
    userPresetsManager?.makeCurrentPreset(number: 0)
  }

  func numberToTag(_ number: Int) -> Int { number >= 0 ? (number + 10000) : number }

  func tagToNumber(_ tag: Int) -> Int { tag >= 10000 ? (tag - 10000) : tag }

  func populatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }
    let audioUnit = userPresetsManager.audioUnit

    for preset in audioUnit.factoryPresetsNonNil {
      let key = "\(preset.number + 1)"
      let menuItem = NSMenuItem(title: preset.name, action: #selector(presetMenuItemSelected(_:)), keyEquivalent: key)
      menuItem.tag = numberToTag(preset.number)
      presetsMenu.addItem(menuItem)
    }

    updatePresetMenu()
  }

  func updatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }
    let active = userPresetsManager.audioUnit.currentPreset?.number ?? Int.max

    savePresetMenuItem.isEnabled = true
    renamePresetMenuItem.isEnabled = active < 0
    deletePresetMenuItem.isEnabled = active < 0

    // Determine number of items to keep: 3 commands + divider + # of factory items
    let factoryCount = userPresetsManager.audioUnit.factoryPresetsNonNil.count
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

  func updateView() {
    updatePresetMenu()
    audioUnitHost.save()
  }
}

// MARK: - Alerts and Prompts

extension MainViewController {

  func notify(title: String, message: String, completion: (() -> Void)? = nil) {
    let alert = NSAlert()

    alert.alertStyle = .informational
    alert.messageText = title
    alert.informativeText = message

    alert.addButton(withTitle: "OK")
    print("before beginSheetModal")
    alert.beginSheetModal(for: view.window!) { _ in completion?() }
  }

  func yesOrNo(title: String, message: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
  }
}
