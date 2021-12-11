// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import UIKit
import os.log

final class MainViewController: UIViewController {

  private let audioUnitHost = AudioUnitHost(componentDescription: FilterAudioUnit.componentDescription)
  internal var userPresetsManager: UserPresetsManager?

  @IBOutlet weak var reviewButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var bypassButton: UIButton!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var presetSelection: UISegmentedControl!
  @IBOutlet weak var userPresetsMenu: UIButton!

  private lazy var renameAction = UIAction(title: "Rename", handler: RenamePresetAction(self).start(_:))
  private lazy var deleteAction = UIAction(title: "Delete", handler: DeletePresetAction(self).start(_:))
  private lazy var saveAction = UIAction(title: "Save", handler: SavePresetAction(self).start(_:))

  private var allParameterValuesObserverToken: NSKeyValueObservation?
  private var parameterTreeObserverToken: AUParameterObserverToken?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
    delegate.setMainViewController(self)

    let version = Bundle.main.releaseVersionNumber
    reviewButton.setTitle(version, for: .normal)

    audioUnitHost.delegate = self
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let showedAlertKey = "showedInitialAlert"
    guard UserDefaults.standard.bool(forKey: showedAlertKey) == false else { return }
    UserDefaults.standard.set(true, forKey: showedAlertKey)
    let alert = UIAlertController(title: "AUv3 Component Installed",
                                  message: nil, preferredStyle: .alert)
    alert.message =
      """
      The AUv3 component '__NAME__' is now available on your device and can be used in other AUv3 host apps such as
      GarageBand, AUM, and Cubasis. You can continue to use this app to experiment, but you do not need to have it
      running to access the AUv3 component in other apps. However, if you later delete this app from your device, the
      AUv3 component will no longer be available in other host apps.
      """
    alert.addAction(
      UIAlertAction(title: "OK", style: .default, handler: { _ in })
    )
    present(alert, animated: true)
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
    userPresetsManager?.makeCurrentPreset(number: presetSelection.selectedSegmentIndex)
  }

  @IBAction private func reviewApp(_ sender: UIButton) {
    AppStore.visitAppStore()
  }
}

extension MainViewController: AudioUnitHostDelegate {
  func connected(audioUnit: AUAudioUnit, viewController: ViewController) {
    userPresetsManager = .init(for: audioUnit)
    connectFilterView(viewController)
    connectParametersToControls(audioUnit)
  }

  func failed(error: AudioUnitHostError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    let controller = UIAlertController(title: "AUv3 Failure", message: message, preferredStyle: .alert)
    present(controller, animated: true)
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

  private func useUserPreset(name: String) {
    guard let userPresetManager = userPresetsManager else { return }
    userPresetManager.makeCurrentPreset(name: name)
    updatePresetMenu()
  }

  func updatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }
    let active = userPresetsManager.audioUnit.currentPreset?.number ?? Int.max

    let presets = userPresetsManager.presetsOrderedByName.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.useUserPreset(name: preset.name) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    let actionsGroup = UIMenu(title: "Actions", options: [],
                              children: active < 0 ? [saveAction, renameAction, deleteAction] : [saveAction])
    let menu = UIMenu(title: "User Presets", options: [], children: presets + [actionsGroup])
    userPresetsMenu.menu = menu
    userPresetsMenu.showsMenuAsPrimaryAction = true
  }

  private func updateView() {
    guard let audioUnit = audioUnitHost.audioUnit else { return }

    updatePresetMenu()
    updatePresetSelection(audioUnit)

    audioUnitHost.save()
  }

  private func updatePresetSelection(_ audioUnit: AUAudioUnit) {
    if let presetNumber = audioUnit.currentPreset?.number {
      presetSelection.selectedSegmentIndex = presetNumber
    } else {
      presetSelection.selectedSegmentIndex = -1
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
