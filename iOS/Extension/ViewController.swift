// Copyright © 2022 Brad Howes. All rights reserved.
#if os(iOS)

import AUv3Support
import CoreAudioKit
import KernelBridge
import Kernel
import Knob_iOS
import ParameterAddress
import Parameters
import Theme

import os.log

extension Knob: AUParameterValueProvider, RangedControl {}

/**
 Controller for the AUv3 filter view. Handles wiring up of the controls with AUParameter settings.
 */
@objc open class ViewController: AUViewController {

  // NOTE: this special form sets the subsystem name and must run before any other logger calls.
  private let log = Shared.logger(Bundle.main.auBaseName + "AU", "ViewController")

  private let parameters = Parameters()
  private var viewConfig: AUAudioUnitViewConfiguration!

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var controlsView: View!

  @IBOutlet weak var depthControl: Knob!
  @IBOutlet weak var depthValueLabel: Label!
  @IBOutlet weak var depthTapEdit: UIView!

  @IBOutlet weak var delayControl: Knob!
  @IBOutlet weak var delayValueLabel: Label!
  @IBOutlet weak var delayTapEdit: UIView!

  @IBOutlet weak var rateControl: Knob!
  @IBOutlet weak var rateValueLabel: Label!
  @IBOutlet weak var rateTapEdit: UIView!

  @IBOutlet weak var feedbackControl: Knob!
  @IBOutlet weak var feedbackValueLabel: Label!
  @IBOutlet weak var feedbackTapEdit: UIView!

  @IBOutlet weak var altDepthControl: Knob!
  @IBOutlet weak var altDepthValueLabel: Label!
  @IBOutlet weak var altDepthTapEdit: View!

  @IBOutlet weak var altDelayControl: Knob!
  @IBOutlet weak var altDelayValueLabel: Label!
  @IBOutlet weak var altDelayTapEdit: View!

  @IBOutlet weak var dryMixControl: Knob!
  @IBOutlet weak var dryMixValueLabel: Label!
  @IBOutlet weak var dryMixTapEdit: UIView!

  @IBOutlet weak var wetMixControl: Knob!
  @IBOutlet weak var wetMixValueLabel: Label!
  @IBOutlet weak var wetMixTapEdit: UIView!

  @IBOutlet weak var odd90Control: Switch!
  @IBOutlet weak var negativeFeedbackControl: Switch!

  @IBOutlet weak var versionTag: UILabel!

  private lazy var controls: [ParameterAddress: [(Knob, Label, UIView)]] = [
    .depth: [(depthControl, depthValueLabel, depthTapEdit),
             (altDepthControl, altDepthValueLabel, altDepthTapEdit)],
    .delay: [(delayControl, delayValueLabel, delayTapEdit),
             (altDelayControl, altDelayValueLabel, altDelayTapEdit)],
    .rate: [(rateControl, rateValueLabel, rateTapEdit)],
    .feedback: [(feedbackControl, feedbackValueLabel, feedbackTapEdit)],
    .wet: [(wetMixControl, wetMixValueLabel, wetMixTapEdit)],
    .dry: [(dryMixControl, dryMixValueLabel, dryMixTapEdit)]
  ]

  private lazy var switches: [ParameterAddress: Switch] = [
    .odd90: odd90Control,
    .negativeFeedback: negativeFeedbackControl
  ]

  // Holds all of the other editing views and is used to end editing when tapped.
  @IBOutlet weak var editingContainerView: View!
  // Background that contains the label and value editor field. Always appears just above the keyboard view.
  @IBOutlet weak var editingBackground: UIView!
  // Shows the name of the value being edited
  @IBOutlet weak var editingLabel: Label!
  // Shows the name of the value being edited
  @IBOutlet weak var editingValue: UITextField!

  // The top constraint of the editingView. Set to 0 when loaded, but otherwise not used.
  @IBOutlet weak var editingViewTopConstraint: NSLayoutConstraint!
  // The bottom constraint of the editingBackground that controls the vertical position of the editor
  @IBOutlet weak var editingBackgroundBottomConstraint: NSLayoutConstraint!

  private var editors = [AUParameterEditor]()
  private var editorMap = [ParameterAddress : [AUParameterEditor]]()

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
  }
}

// MARK: - AudioUnitViewConfigurationManager

extension ViewController: AudioUnitViewConfigurationManager {}

// MARK: - AUAudioUnitFactory

extension ViewController: AUAudioUnitFactory {
  @objc public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    let bundle = InternalConstants.bundle

    DispatchQueue.main.async {
      self.versionTag.text = bundle.versionTag
    }

    let kernel = KernelBridge(bundle.auBaseName, maxDelayMilliseconds: parameters[.delay].maxValue)
    let audioUnit = try FilterAudioUnitFactory.create(componentDescription: componentDescription,
                                                      parameters: parameters, kernel: kernel,
                                                      viewConfigurationManager: self)
    self.audioUnit = audioUnit
    return audioUnit
  }
}

// MARK: - Private

extension ViewController: AUParameterEditorDelegate {

  public func parameterEditorEditingDone(changed: Bool) {
    if changed {
      audioUnit?.clearCurrentPresetIfFactoryPreset()
    }
  }

  private func createEditors() {
    os_log(.info, log: log, "createEditors BEGIN")

    let knobColor = UIColor(named: "knob")!

    let valueEditor = ValueEditor(containerView: editingContainerView, backgroundView: editingBackground,
                                  parameterName: editingLabel, parameterValue: editingValue,
                                  containerViewTopConstraint: editingViewTopConstraint,
                                  backgroundViewBottomConstraint: editingBackgroundBottomConstraint,
                                  controlsView: controlsView)

    for (parameterAddress, pairs) in controls {
      var editors = [AUParameterEditor]()
      for (knob, label, tapEdit) in pairs {
        knob.progressColor = knobColor
        knob.indicatorColor = knobColor

        knob.addTarget(self, action: #selector(handleKnobChanged(_:)), for: .valueChanged)
        let editor = FloatParameterEditor(parameter: parameters[parameterAddress],
                                          formatting: parameters[parameterAddress],
                                          rangedControl: knob, label: label)
        self.editors.append(editor)
        editors.append(editor)
        editor.setValueEditor(valueEditor: valueEditor, tapToEdit: tapEdit)
      }
      editorMap[parameterAddress] = editors
    }

    os_log(.info, log: log, "createEditors - creating bool parameter editors")
    for (parameterAddress, control) in switches {
      os_log(.info, log: log, "createEditors - before BooleanParameterEditor")
      control.addTarget(self, action: #selector(handleSwitchChanged(_:)), for: .valueChanged)

      let editor = BooleanParameterEditor(parameter: parameters[parameterAddress], booleanControl: control)
      editors.append(editor)
      editorMap[parameterAddress] = [editor]
    }

    os_log(.info, log: log, "createEditors END")
  }

  @objc public func handleKnobChanged(_ control: Knob) {
    guard let address = control.parameterAddress else { fatalError() }
    handleControlChanged(control, address: address)
  }

  @objc public func handleSwitchChanged(_ control: Switch) {
    guard let address = control.parameterAddress else { fatalError() }
    handleControlChanged(control, address: address)
  }

  private func handleControlChanged(_ control: AUParameterValueProvider, address: ParameterAddress) {
    os_log(.debug, log: log, "controlChanged BEGIN - %d %f", address.rawValue, control.value)

    guard let audioUnit = audioUnit else {
      os_log(.debug, log: log, "controlChanged END - nil audioUnit")
      return
    }

    guard let editors = editorMap[address] else {
      os_log(.debug, log: log, "controlChanged END - nil ediitors")
      return
    }

    if editors.contains(where: { $0.differs }) {
      audioUnit.clearCurrentPresetIfFactoryPreset()
    }

    editors.forEach { $0.controlChanged(source: control) }

    os_log(.debug, log: log, "controlChanged END")
  }
}

private enum InternalConstants {
  private class EmptyClass {}
  static let bundle = Bundle(for: InternalConstants.EmptyClass.self)
}

#endif
