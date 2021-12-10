// Copyright © 2021 Apple. All rights reserved.

import AppKit

internal enum PromptForReply {
  internal enum Response {
    case ok(value: String)
    case cancel
  }

  static func ask(title: String, message: String) -> Response {
    let alert = NSAlert()

    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")

    alert.messageText = title
    alert.informativeText = message

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.placeholderString = "Preset Name"
    textField.stringValue = ""

    alert.accessoryView = textField
    alert.layout()
    alert.accessoryView?.becomeFirstResponder()

    let response: NSApplication.ModalResponse = alert.runModal()
    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
      return .ok(value: textField.stringValue)
    }
    return .cancel
  }
}
