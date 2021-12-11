// Copyright © 2021 Brad Howes. All rights reserved.

import AppKit
import __NAME__Framework

extension MainViewController {
  struct RenamePresetAction {
    let viewController: MainViewController
    let userPresetsManager: UserPresetsManager

    init(_ viewController: MainViewController) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
    }

    func start(_ action: AnyObject) {
      let response = PromptForReply.ask(title: "Save Preset", message: "")
      if case .ok(let value) = response {
        let name = value.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
          self.renamePreset(with: name)
        }
      }
    }

    func renamePreset(with name: String) {
      do {
        try userPresetsManager.renameCurrent(to: name)
      } catch {
        viewController.notify(title: "Rename Error", message: error.localizedDescription)
      }
      viewController.updatePresetMenu()
    }
  }
}
