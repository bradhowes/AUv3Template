// Copyright © 2021 Brad Howes. All rights reserved.

import Cocoa
import FilterFramework

final class MainViewController: NSViewController {

    private var audioUnitManager: AudioUnitManager!

    private var playButton: NSButton!
    private var bypassButton: NSButton!
    private var playMenuItem: NSMenuItem!
    private var bypassMenuItem: NSMenuItem!
    private var savePresetMenuItem: NSMenuItem!

    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var loadingText: NSTextField!

    private var windowController: MainWindowController? { view.window?.windowController as? MainWindowController }
    private var appDelegate: AppDelegate? { NSApplication.shared.delegate as? AppDelegate }

    private var filterView: NSView?
    private var parameterObserverToken: AUParameterObserverToken?
}

// MARK: - View Management
extension MainViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        audioUnitManager = AudioUnitManager(componentDescription: FilterAudioUnit.componentDescription,
                                            appExtension: Bundle.main.auExtensionName)
        audioUnitManager.delegate = self
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        guard let appDelegate = appDelegate,
              let windowController = windowController else {
            fatalError()
        }

        view.window?.delegate = self
        savePresetMenuItem = appDelegate.savePresetMenuItem
        guard savePresetMenuItem != nil else { fatalError() }

        playButton = windowController.playButton
        playMenuItem = appDelegate.playMenuItem

        bypassButton = windowController.bypassButton
        bypassMenuItem = appDelegate.bypassMenuItem
        bypassButton.isEnabled = false
        bypassMenuItem.isEnabled = false

        savePresetMenuItem.isHidden = true
        savePresetMenuItem.isEnabled = false
        savePresetMenuItem.target = self
        savePresetMenuItem.action = #selector(handleSavePresetMenuSelection(_:))
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
The AUv3 component '__NAME__' is now available on your system.

This app uses the component to demonstrate how it works and sounds.
"""
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: view.window!){ _ in }
    }
}

extension MainViewController: AudioUnitManagerDelegate {

    func connected() {
        guard filterView == nil else { return }
        connectFilterView()
    }
}

extension MainViewController {

    @IBAction private func togglePlay(_ sender: NSButton) {
        audioUnitManager.togglePlayback()
        playButton?.state = audioUnitManager.isPlaying ? .on : .off
        playButton?.title = audioUnitManager.isPlaying ? "Stop" : "Play"
        playMenuItem?.title = audioUnitManager.isPlaying ? "Stop" : "Play"
        bypassButton?.isEnabled = audioUnitManager.isPlaying
        bypassMenuItem?.isEnabled = audioUnitManager.isPlaying
    }

    @IBAction private func toggleBypass(_ sender: NSButton) {
        let wasBypassed = audioUnitManager.audioUnit?.shouldBypassEffect ?? false
        let isBypassed = !wasBypassed
        audioUnitManager.audioUnit?.shouldBypassEffect = isBypassed
        bypassButton?.state = isBypassed ? .on : .off
        bypassButton?.title = isBypassed ? "Resume" : "Bypass"
        bypassMenuItem?.title = isBypassed ? "Resume" : "Bypass"
    }

    @objc private func handleSavePresetMenuSelection(_ sender: NSMenuItem) throws {
        guard let audioUnit = audioUnitManager.viewController.audioUnit else { return }
        guard let presetMenu = NSApplication.shared.mainMenu?.item(withTag: 666)?.submenu else { return }

        let preset = AUAudioUnitPreset()
        let index = audioUnit.userPresets.count + 1
        preset.name = "Preset \(index)"
        preset.number = -index

        do {
            try audioUnit.saveUserPreset(preset)
        } catch {
            print(error.localizedDescription)
        }

        let menuItem = NSMenuItem(title: preset.name,
                                  action: #selector(handlePresetMenuSelection(_:)),
                                  keyEquivalent: "")
        menuItem.tag = preset.number
        presetMenu.addItem(menuItem)
    }

    @objc private func handlePresetMenuSelection(_ sender: NSMenuItem) {
        guard let audioUnit = audioUnitManager.viewController.audioUnit else { return }
        sender.menu?.items.forEach { $0.state = .off }
        if sender.tag >= 0 {
            audioUnit.currentPreset = audioUnit.factoryPresets[sender.tag]
        }
        else {
            audioUnit.currentPreset = audioUnit.userPresets[sender.tag]
        }

        sender.state = .on
    }
}

extension MainViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        audioUnitManager.cleanup()
        guard let parameterTree = audioUnitManager.viewController.audioUnit?.parameterTree,
            let parameterObserverToken = parameterObserverToken else { return }
        parameterTree.removeParameterObserver(parameterObserverToken)
    }
}

extension MainViewController {

    private func connectFilterView() {
        let viewController = audioUnitManager.viewController
        let filterView = viewController.view
        containerView.addSubview(filterView)
        filterView.pinToSuperviewEdges()
        self.filterView = filterView

        addChild(viewController)
        view.needsLayout = true
        containerView.needsLayout = true
        loadingText.isHidden = true

        populatePresetMenu(audioUnitManager.audioUnit!)
    }

    private func populatePresetMenu(_ audioUnit: FilterAudioUnit) {
        guard let presetMenu = NSApplication.shared.mainMenu?.item(withTag: 666)?.submenu else { return }
        for preset in audioUnit.factoryPresets {
            let keyEquivalent = "\(preset.number + 1)"
            let menuItem = NSMenuItem(title: preset.name, action: #selector(handlePresetMenuSelection(_:)),
                                      keyEquivalent: keyEquivalent)
            menuItem.tag = preset.number
            presetMenu.addItem(menuItem)
        }

        if let currentPreset = audioUnit.currentPreset {
            presetMenu.item(at: currentPreset.number + 2)?.state = .on
        }
    }
}
