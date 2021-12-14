// Copyright © 2021 Brad Howes. All rights reserved.

import AppKit
import __NAME__Framework

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

    func start(_ action: AnyObject) {
      let response = PromptForReply.ask(title: "Save Preset", message: "")
      if case .ok(let value) = response {
        let name = value.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
          self.checkIsUniquePreset(named: name)
        }
      }
    }

    func checkIsUniquePreset(named name: String) {
      guard let existing = userPresetsManager.find(name: name) else {
        save(under: name)
        return
      }

      if viewController.yesOrNo(title: "Existing Preset",
                                message: "Do you wish to change the existing preset to have the current settings?") {
        update(preset: existing)
      }
    }

    func save(under name: String) {
      do {
        try userPresetsManager.create(name: name)
      } catch {
        viewController.notify(title: "Save Error", message: error.localizedDescription)
      }
      completion()
    }

    func update(preset: AUAudioUnitPreset) {
      do {
        try userPresetsManager.update(preset: preset)
      } catch {
        viewController.notify(title: "Update Error", message: error.localizedDescription)
      }
      completion()
    }
  }
}
