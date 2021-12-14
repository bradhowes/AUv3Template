// Copyright © 2021 Brad Howes. All rights reserved.

import __NAME__Framework
import UIKit

extension MainViewController {

  /**
   Flow involved in creating a new user preset or updating an existing one.
   */
  struct SavePresetAction {
    let viewController: MainViewController
    let userPresetsManager: UserPresetsManager
    let completion: () -> Void

    init(_ viewController: MainViewController, completion: @escaping () -> Void) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
      self.completion = completion
    }

    func start(_ action: UIAction) {
      let controller = UIAlertController(title: "Save Preset", message: nil, preferredStyle: .alert)
      controller.addTextField { textField in textField.placeholder = "Preset Name" }
      controller.addAction(UIAlertAction(title: "Save", style: .default) { _ in
        guard let name = controller.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) else { return }
        if !name.isEmpty {
          self.checkIsUniquePreset(named: name)
        }
      })

      controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      viewController.present(controller, animated: true)
    }

    func checkIsUniquePreset(named name: String) {
      guard let existing = userPresetsManager.find(name: name) else {
        save(under: name)
        return
      }

      viewController.yesOrNo("Existing Preset",
                             message: "Do you wish to change the existing preset to have the current settings?") { _ in
        self.update(preset: existing)
      }
    }

    func save(under name: String) {
      do {
        try userPresetsManager.create(name: name)
      } catch {
        viewController.notify("Save Error", message: error.localizedDescription)
      }
      completion()
    }

    func update(preset: AUAudioUnitPreset) {
      do {
        try userPresetsManager.update(preset: preset)
      } catch {
        viewController.notify("Update Error", message: error.localizedDescription)
      }
      completion()
    }
  }
}
