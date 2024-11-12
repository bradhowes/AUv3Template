// Copyright © 2021 Brad Howes. All rights reserved.

#if os(macOS)

import Cocoa

/**
 Main window controller for the host app. Only exists here so that others can access the buttons defined in the
 Main.storyboard file.
 */
final class MainWindowController: NSWindowController {
  @IBOutlet public weak var playButton: NSButton!
  @IBOutlet public weak var bypassButton: NSButton!
  @IBOutlet public weak var presetsButton: NSPopUpButton!
}

#endif
