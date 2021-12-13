// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import UIKit

extension MainViewController {

  /**
   Flow involved in renaming an existing user preset.
   */
  struct RenamePresetAction {
    let viewController: MainViewController
    let userPresetsManager: UserPresetsManager

    init(_ viewController: MainViewController) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
    }

    func start(_ action: UIAction) {
      let controller = UIAlertController(title: "Rename Preset", message: nil, preferredStyle: .alert)
      controller.addTextField { textField in textField.placeholder = "New Name" }
      controller.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
        guard let name = controller.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty
        else {
          return
        }
        self.renamePreset(with: name)
      })

      controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      viewController.present(controller, animated: true)
    }

    func renamePreset(with name: String) {
      do {
        try userPresetsManager.renameCurrent(to: name)
      } catch {
        viewController.notify("Rename Error", message: error.localizedDescription)
      }
      viewController.updatePresetMenu()
    }
  }
}
