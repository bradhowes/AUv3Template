// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import UIKit
import os.log

/**
 Main view controller for the app. Shows controls for the filter audio unit as well as controls for preset management.
 */
final class MainViewController: UIViewController {

  private var audioUnitHost: AudioUnitHost!
  internal var userPresetsManager: UserPresetsManager?

  @IBOutlet weak var reviewButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var bypassButton: UIButton!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var factoryPresetSegmentedControl: UISegmentedControl!
  @IBOutlet weak var userPresetsMenuButton: UIButton!

  @IBOutlet weak var instructions: UIView!

  private lazy var saveAction = UIAction(title: "Save", handler: SavePresetAction(self).start(_:))
  private lazy var renameAction = UIAction(title: "Rename", handler: RenamePresetAction(self).start(_:))
  private lazy var deleteAction = UIAction(title: "Delete", attributes: .destructive,
                                           handler: DeletePresetAction(self).start(_:))

  private var allParameterValuesObserverToken: NSKeyValueObservation?
  private var parameterTreeObserverToken: AUParameterObserverToken?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
    delegate.setMainViewController(self)

    let version = Bundle.main.releaseVersionNumber
    reviewButton.setTitle(version, for: .normal)

    audioUnitHost = .init(componentDescription: Bundle.shared.componentDescription)
    audioUnitHost.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let showedAlertKey = "showedInitialAlert"
#if !Dev
    guard UserDefaults.standard.bool(forKey: showedAlertKey) == false else {
      instructions.isHidden = true
      return
    }
    UserDefaults.standard.set(true, forKey: showedAlertKey)
#endif

    instructions.layer.borderWidth = 4
    instructions.layer.borderColor = UIColor.systemOrange.cgColor
    instructions.layer.cornerRadius = 16
  }

  public func stopPlaying() {
    audioUnitHost.cleanup()
  }

  @IBAction private func togglePlay(_ sender: UIButton) {
    let isPlaying = audioUnitHost.togglePlayback()
    sender.isSelected = isPlaying
    sender.tintColor = isPlaying ? .systemYellow : .systemTeal
  }

  @IBAction private func toggleBypass(_ sender: UIButton) {
    let wasBypassed = audioUnitHost.audioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    audioUnitHost.audioUnit?.shouldBypassEffect = isBypassed
    sender.isSelected = isBypassed
  }

  @IBAction private func visitAppStore(_ sender: UIButton) {
    let appStoreId = Bundle.main.appStoreId
    guard let url = URL(string: "https://itunes.apple.com/app/id\(appStoreId)") else {
      fatalError("Expected a valid URL")
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }

  @IBAction func useFactoryPreset(_ sender: UISegmentedControl? = nil) {
    userPresetsManager?.makeCurrentPreset(number: factoryPresetSegmentedControl.selectedSegmentIndex)
  }

  @IBAction private func reviewApp(_ sender: UIButton) {
    AppStore.visitAppStore()
  }

  @IBAction func dismissInstructions(_ sender: Any) {
    instructions.isHidden = true
  }
}

extension MainViewController: AudioUnitHostDelegate {

  func connected(audioUnit: AUAudioUnit, viewController: ViewController) {
    userPresetsManager = .init(for: audioUnit)
    connectFilterView(viewController)
    connectParametersToControls(audioUnit)
    showInstructions()
  }

  func failed(error: AudioUnitHostError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    let controller = UIAlertController(title: "AUv3 Failure", message: message, preferredStyle: .alert)
    present(controller, animated: true)
  }

  private func showInstructions() {
    let showedAlertKey = "showedInitialAlert"
#if !Dev
    guard UserDefaults.standard.bool(forKey: showedAlertKey) == false else {
      instructions.isHidden = true
      return
    }
    UserDefaults.standard.set(true, forKey: showedAlertKey)
#endif
    instructions.isHidden = false
  }

  private func connectFilterView(_ viewController: UIViewController) {
    let filterView = viewController.view!
    containerView.addSubview(filterView)
    filterView.pinToSuperviewEdges()

    addChild(viewController)
    view.setNeedsLayout()
    containerView.setNeedsLayout()
  }

  private func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    guard let parameterTree = audioUnit.parameterTree else {
      fatalError("FilterAudioUnit does not define any parameters.")
    }

    audioUnitHost.restore()
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

  private func usePreset(number: Int) {
    guard let userPresetManager = userPresetsManager else { return }
    userPresetManager.makeCurrentPreset(number: number)
    updatePresetMenu()
  }

  func updatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }
    let active = userPresetsManager.audioUnit.currentPreset?.number ?? Int.max

    let factoryPresets = userPresetsManager.audioUnit.factoryPresetsNonNil.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.usePreset(number: preset.number) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    let factoryPresetsMenu = UIMenu(title: "Factory", options: .displayInline, children: factoryPresets)

    let userPresets = userPresetsManager.presetsOrderedByName.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.usePreset(number: preset.number) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    let userPresetsMenu = UIMenu(title: "User", options: .displayInline, children: userPresets)

    let actionsGroup = UIMenu(title: "Actions", options: .displayInline,
                              children: active < 0 ? [saveAction, renameAction, deleteAction] : [saveAction])

    let menu = UIMenu(title: "Presets", options: [], children: [userPresetsMenu, factoryPresetsMenu, actionsGroup])

    userPresetsMenuButton.menu = menu
    userPresetsMenuButton.showsMenuAsPrimaryAction = true
  }

  private func updateView() {
    guard let audioUnit = audioUnitHost.audioUnit else { return }

    updatePresetMenu()
    updatePresetSelection(audioUnit)

    audioUnitHost.save()
  }

  private func updatePresetSelection(_ audioUnit: AUAudioUnit) {
    if let presetNumber = audioUnit.currentPreset?.number {
      factoryPresetSegmentedControl.selectedSegmentIndex = presetNumber
    } else {
      factoryPresetSegmentedControl.selectedSegmentIndex = -1
    }
  }
}

extension MainViewController {

  func notify(_ title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .default))
    present(controller, animated: true)
  }

  func yesOrNo(_ title: String, message: String, continuation: @escaping (UIAlertAction) -> Void) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(.init(title: "Continue", style: .default, handler: continuation))
    controller.addAction(.init(title: "Cancel", style: .cancel))
    present(controller, animated: true)
  }
}
