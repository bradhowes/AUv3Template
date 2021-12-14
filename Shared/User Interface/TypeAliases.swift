// Copyright © 2021 Brad Howes. All rights reserved.

#if os(iOS)

import UIKit
public typealias Color = UIColor
public typealias Label = UILabel
public typealias Slider = UISlider
public typealias Storyboard = UIStoryboard
public typealias Switch = UISwitch
public typealias View = UIView
public typealias ViewController = UIViewController

#elseif os(macOS)

import AppKit
public typealias Color = NSColor
public typealias Label = FocusAwareTextField
public typealias Slider = NSSlider
public typealias Storyboard = NSStoryboard
public typealias Switch = NSSwitch
public typealias View = NSView
public typealias ViewController = NSViewController

public extension NSView {
  func setNeedsDisplay() { needsDisplay = true }
  func setNeedsLayout() { needsLayout = true }

  @objc func layoutSubviews() { layout() }

  var backgroundColor: NSColor? {
    get {
      guard let colorRef = layer?.backgroundColor else { return nil }
      return NSColor(cgColor: colorRef)
    }
    set {
      wantsLayer = true
      layer?.backgroundColor = newValue?.cgColor
    }
  }
}

public extension NSTextField {
  var text: String? {
    get { stringValue }
    set { stringValue = newValue ?? "" }
  }
}

public extension NSSwitch {
  var isOn: Bool {
    get { state == .on }
    set { state = newValue ? .on : .off }
  }
}

public extension NSSlider {
  var minimumValue: Float {
    get { Float(minValue) }
    set { minValue = Double(newValue) }
  }

  var maximumValue: Float {
    get { Float(maxValue) }
    set { maxValue = Double(newValue) }
  }

  var value: Float {
    get { floatValue }
    set { floatValue = newValue }
  }
}

/**
 This seems like a hack, but it works. Allow for others to identify when a NSTextField is the first responder. There
 are notifications from the NSWindow but this seems to be the easiest for AUv3 work.
 */
public final class FocusAwareTextField: NSTextField {
  public var onFocusChange: (Bool) -> Void = { _ in }

  override public func becomeFirstResponder() -> Bool {
    onFocusChange(true)
    return super.becomeFirstResponder()
  }

  func setStringValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
    guard stringValue != newValue else { return }
    if animated {
      animate(change: { self.stringValue = newValue }, interval: interval)
    } else {
      stringValue = newValue
    }
  }

  private func animate(change: @escaping () -> Void, interval: TimeInterval) {
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = interval / 2.0
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      self.animator().alphaValue = 0.5
    }, completionHandler: {
      change()
      NSAnimationContext.runAnimationGroup({ context in
        context.duration = interval / 2.0
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        self.animator().alphaValue = 1.0
      }, completionHandler: {})
    })
  }
}

#endif
