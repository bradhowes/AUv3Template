// Copyright © 2021 Brad Howes. All rights reserved.

import os

private class Tag {}

public enum Logging {
  /// The top-level identifier to use for logging
  public static let subsystem = "LPF"

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  public static func logger(_ category: String) -> OSLog { OSLog(subsystem: subsystem, category: category) }
}
