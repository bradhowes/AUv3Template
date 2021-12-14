// Copyright © 2021 Brad Howes. All rights reserved.

import AppKit
import __NAME__Framework

extension MainViewController {

  /**
   Flow involved in deleting an existing user preset.
   */
  struct DeletePresetAction {
    let viewController: MainViewController
    let userPresetsManager: UserPresetsManager
    let completion: () -> Void

    init(_ viewController: MainViewController, completion: @escaping () -> Void) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
      self.completion = completion
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
      completion()
    }
  }
}
