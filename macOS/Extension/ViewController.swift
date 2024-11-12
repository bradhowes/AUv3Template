// Copyright © 2022 Brad Howes. All rights reserved.

#if os(macOS)

import AUv3Support
import CoreAudioKit
import Kernel
import KernelBridge
import Knob_macOS
import ParameterAddress
import Parameters
import os.log

extension Knob: @retroactive AUParameterValueProvider, @retroactive RangedControl {}

/**
 Controller for the AUv3 filter view. Handles wiring up of the controls with AUParameter settings.
 */
@objc final public class ViewController: AUViewController {

  // NOTE: this special form sets the subsystem name and must run before any other logger calls.
  private let log: OSLog = Shared.logger(Bundle.main.auBaseName + "AU", "ViewController")

  private let parameters = Parameters()
  private var viewConfig: AUAudioUnitViewConfiguration!
  private var versionTagValue: String = ""

  @IBOutlet private weak var controlsView: NSView!

  @IBOutlet private weak var depthControl: Knob!
  @IBOutlet private weak var depthValueLabel: FocusAwareTextField!

  @IBOutlet private weak var delayControl: Knob!
  @IBOutlet private weak var delayValueLabel: FocusAwareTextField!

  @IBOutlet private weak var rateControl: Knob!
  @IBOutlet private weak var rateValueLabel: FocusAwareTextField!

  @IBOutlet private weak var feedbackControl: Knob!
  @IBOutlet private weak var feedbackValueLabel: FocusAwareTextField!

  @IBOutlet private weak var wetMixControl: Knob!
  @IBOutlet private weak var wetMixValueLabel: FocusAwareTextField!

  @IBOutlet private weak var dryMixControl: Knob!
  @IBOutlet private weak var dryMixValueLabel: FocusAwareTextField!

  @IBOutlet private weak var odd90Control: NSSwitch!
  @IBOutlet private weak var negativeFeedbackControl: NSSwitch!

  @IBOutlet private weak var versionTag: NSTextField!

  private lazy var controls: [ParameterAddress: (Knob, FocusAwareTextField)] = [
    .depth: (depthControl, depthValueLabel),
    .rate: (rateControl, rateValueLabel),
    .delay: (delayControl, delayValueLabel),
    .feedback: (feedbackControl, feedbackValueLabel),
    .wet: (wetMixControl, wetMixValueLabel),
    .dry: (dryMixControl, dryMixValueLabel)
  ]

  private lazy var switches: [ParameterAddress: NSSwitch] = [
    .odd90: odd90Control,
    .negativeFeedback: negativeFeedbackControl
  ]

  private var editors = [AUParameterEditor]()
  private var editorMap = [ParameterAddress : AUParameterEditor]()

  public var audioUnit: FilterAudioUnit? {
    didSet {
      DispatchQueue.main.async {
        if self.isViewLoaded {
          self.createEditors()
        }
      }
    }
  }
}

public extension ViewController {

  override func viewDidLoad() {
    os_log(.info, log: log, "viewDidLoad BEGIN")
    super.viewDidLoad()
    view.backgroundColor = .black

    if audioUnit != nil {
      createEditors()
    }
    os_log(.info, log: log, "viewDidLoad END")
  }

  override func viewDidAppear() {
    versionTag.text = versionTagValue
  }

  override func mouseDown(with event: NSEvent) {
    // Allow for clicks on the common NSView to end editing of values
    NSApp.keyWindow?.makeFirstResponder(nil)
  }
}

// MARK: - AudioUnitViewConfigurationManager

extension ViewController: AudioUnitViewConfigurationManager {}

// MARK: - AUAudioUnitFactory

extension ViewController: AUAudioUnitFactory {
  @objc public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    let bundle = InternalConstants.bundle

    let kernel = KernelBridge(bundle.auBaseName, maxDelayMilliseconds: parameters[.delay].maxValue)
    let audioUnit = try FilterAudioUnitFactory.create(componentDescription: componentDescription,
                                                      parameters: parameters,
                                                      kernel: kernel,
                                                      viewConfigurationManager: self)
    self.versionTagValue = bundle.versionTag
    self.audioUnit = audioUnit
    return audioUnit
  }
}

extension ViewController: AUParameterEditorDelegate {
  public func parameterEditorEditingDone(changed: Bool) {
    if changed {
      audioUnit?.clearCurrentPresetIfFactoryPreset()
    }
  }
}

// MARK: - Private

private extension ViewController {

  func createEditors() {
    os_log(.info, log: log, "createEditors BEGIN")

    let knobColor = NSColor(named: "knob")!

    for (parameterAddress, (knob, label)) in controls {
      knob.progressColor = knobColor
      knob.indicatorColor = knobColor

      knob.target = self
      knob.action = #selector(handleKnobChanged(_:))

      let editor = FloatParameterEditor(parameter: parameters[parameterAddress],
                                        formatting: parameters[parameterAddress],
                                        rangedControl: knob, label: label)
      editors.append(editor)
      editorMap[parameterAddress] = editor
    }

    for (parameterAddress, control) in switches {
      control.setTint(knobColor)
      control.target = self
      control.action = #selector(handleSwitchChanged(_:))

      let editor = BooleanParameterEditor(parameter: parameters[parameterAddress], booleanControl: control)
      editors.append(editor)
      editorMap[parameterAddress] = editor
    }

    os_log(.info, log: log, "createEditors END")
  }

  @IBAction func handleKnobChanged(_ control: Knob) {
    guard let address = control.parameterAddress else { fatalError() }
    handleControlChanged(control, address: address)
  }

  @IBAction func handleSwitchChanged(_ control: NSSwitch) {
    guard let address = control.parameterAddress else { fatalError() }
    handleControlChanged(control, address: address)
  }

  func handleControlChanged(_ control: AUParameterValueProvider, address: ParameterAddress) {
    os_log(.debug, log: log, "controlChanged BEGIN - %d %f", address.rawValue, control.value)

    guard let audioUnit = audioUnit else {
      os_log(.debug, log: log, "controlChanged END - nil audioUnit")
      return
    }

    guard let editor = editorMap[address] else {
      os_log(.debug, log: log, "controlChanged END - nil editor")
      return
    }

    if editor.differs {
      // When user changes something and a factory preset was active, clear it.
      if let preset = audioUnit.currentPreset, preset.number >= 0 {
        os_log(.debug, log: log, "controlChanged - clearing currentPreset")
        audioUnit.currentPreset = nil
      }
    }

    editor.controlChanged(source: control)
  }
}

private enum InternalConstants {
  private class EmptyClass {}
  static let bundle = Bundle(for: InternalConstants.EmptyClass.self)
}

#endif
