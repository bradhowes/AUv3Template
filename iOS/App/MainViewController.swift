// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import UIKit

final class MainViewController: UIViewController {
  private let audioUnitHost = AudioUnitHost(interfaceName: "MainInterface")

  @IBOutlet var reviewButton: UIButton!
  @IBOutlet var playButton: UIButton!
  @IBOutlet var bypassButton: UIButton!
  @IBOutlet var containerView: UIView!
  @IBOutlet var preset1Button: UIButton!
  @IBOutlet var preset2Button: UIButton!

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
      The AUv3 component '__NAME__' is now available on your device and can be used in other AUv3 host apps such as GarageBand, AUM, and Cubasis.

      You can continue to use this app to experiment, but you do not need to have it running to access the AUv3 component in other apps.

      However, if you later delete this app from your device, the AUv3 component will no longer be available in other host apps.
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
    let titleText = isPlaying ? "Stop" : "Play"
    playButton.setTitle(titleText, for: .normal)
    playButton.setTitleColor(isPlaying ? .systemRed : .systemTeal, for: .normal)
  }

  @IBAction private func toggleBypass(_ sender: UIButton) {
    let wasBypassed = audioUnitHost.audioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    audioUnitHost.audioUnit?.shouldBypassEffect = isBypassed

    let titleText = isBypassed ? "Resume" : "Bypass"
    bypassButton.setTitle(titleText, for: .normal)
    bypassButton.setTitleColor(isBypassed ? .systemYellow : .systemTeal, for: .normal)
  }

  @IBAction private func visitAppStore(_ sender: UIButton) {
    let appStoreId = Bundle.main.appStoreId
    guard let url = URL(string: "https://itunes.apple.com/app/id\(appStoreId)") else {
      fatalError("Expected a valid URL")
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }

  @IBAction func usePreset1(_ sender: Any) {
    audioUnitHost.audioUnit?.currentPreset = audioUnitHost.audioUnit?.factoryPresets[1]
  }

  @IBAction func usePreset2(_ sender: Any) {
    audioUnitHost.audioUnit?.currentPreset = audioUnitHost.audioUnit?.factoryPresets[2]
  }

  @IBAction private func reviewApp(_ sender: UIButton) {
    AppStore.visitAppStore()
  }
}

extension MainViewController: AudioUnitManagerDelegate {
  func connected() {
    connectFilterView()
  }
}

extension MainViewController {
  private func connectFilterView() {
    let viewController = audioUnitHost.viewController
    guard let filterView = viewController.view else { fatalError("no view found from audio unit") }
    containerView.addSubview(filterView)
    filterView.pinToSuperviewEdges()

    addChild(viewController)
    view.setNeedsLayout()
    containerView.setNeedsLayout()
  }
}
