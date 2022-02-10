// Copyright © 2021 Brad Howes. All rights reserved.

import AUv3Support
import AUv3Support_iOS
import CoreAudioKit
import UIKit

final class MainViewController: UIViewController {

  private var hostViewController: HostViewController!

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }

    let bundle = Bundle.main
    let component = AudioComponentDescription(componentType: bundle.auComponentType,
                                              componentSubType: bundle.auComponentSubtype,
                                              componentManufacturer: bundle.auComponentManufacturer,
                                              componentFlags: 0, componentFlagsMask: 0)

    let tintColor = UIColor(named: "label")!
    let config = HostViewConfig(name: bundle.auBaseName, version: bundle.releaseVersionNumber,
                                appStoreId: bundle.appStoreId,
                                componentDescription: component, sampleLoop: .sample1,
                                tintColor: tintColor) { url in
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    let hostViewController = Shared.embedHostView(into: self, config: config)
    delegate.setStopPlayingBlock { hostViewController.stopPlaying() }
    self.hostViewController = hostViewController
  }
}

