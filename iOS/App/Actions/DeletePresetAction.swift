// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import UIKit

extension MainViewController {

  /**
   Flow involved in deleting an existing user preset.
   */
  struct DeletePresetAction {
    let viewController: MainViewController
    let userPresetsManager: UserPresetsManager

    init(_ viewController: MainViewController) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
    }

    func start(_ action: UIAction) {
      let controller = UIAlertController(title: "Delete Preset",
                                         message: "Do you wish to delete the preset? This cannot be undone.",
                                         preferredStyle: .alert)
      controller.addAction(.init(title: "Cancel", style: .cancel))
      controller.addAction(.init(title: "Continue", style: .destructive) { _ in
        self.deletePreset()
      })
      viewController.present(controller, animated: true)
    }

    func deletePreset() {
      do {
        try userPresetsManager.deleteCurrent()
      } catch {
        viewController.notify("Delete Error", message: error.localizedDescription)
      }
      viewController.updatePresetMenu()
    }
  }
}
