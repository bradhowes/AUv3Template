// Copyright © 2021 Brad Howes. All rights reserved.

import AppKit
import __NAME__Framework

extension MainViewController {
  struct DeletePresetAction {
    let viewController: MainViewController
    let userPresetsManager: UserPresetsManager

    init(_ viewController: MainViewController) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
    }

    func start(_ action: AnyObject) {
      let response = viewController.yesOrNo(title: "Delete Preset",
                                            message: "Do you wish to delete the preset? This cannot be undone.")
      if response {
        deletePreset()
      }
    }

    func deletePreset() {
      do {
        try userPresetsManager.deleteCurrent()
      } catch {
        viewController.notify(title: "Delete Error", message: error.localizedDescription)
      }
    }
  }
}
