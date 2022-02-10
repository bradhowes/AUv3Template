// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import CoreAudioKit
import KernelBridge
import Kernel
import Knob_iOS
import ParameterAddress
import Parameters
import os.log

extension Knob: AUParameterValueProvider, RangedControl {}

/**
 Controller for the AUv3 filter view. Handles wiring up of the controls with AUParameter settings.
 */
@objc open class ViewController: AUViewController {

  // NOTE: this special form sets the subsystem name and must run before any other logger calls.
  private let log = Shared.logger(Bundle.main.auBaseName + "AU", "ViewController")

  private let parameters = AudioUnitParameters()
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

  // Mapping of parameter address value to array of controls. Use array since two controls exist in pairs to handle
  // constrained width layouts.
  private var editors = [ParameterAddress : [AUParameterEditor]]()

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
    let kernel = KernelBridge(Bundle.main.auBaseName, maxDelayMilliseconds: parameters[.delay].maxValue)
    let audioUnit = try FilterAudioUnitFactory.create(componentDescription: componentDescription,
                                                      parameters: parameters, kernel: kernel,
                                                      viewConfigurationManager: self)
    self.audioUnit = audioUnit
    return audioUnit
  }
}

// MARK: - Private

extension ViewController {

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

        let trackWidth: CGFloat = parameterAddress == .dry || parameterAddress == .wet ? 8 : 10
        let progressWidth = trackWidth - 2.0
        knob.trackLineWidth = trackWidth
        knob.progressLineWidth = progressWidth
        knob.indicatorLineWidth = progressWidth

        let editor = FloatParameterEditor(parameter: parameters[parameterAddress],
                                          formatter: parameters.valueFormatter(parameterAddress),
                                          rangedControl: knob, label: label)
        editors.append(editor)
        editor.setValueEditor(valueEditor: valueEditor, tapToEdit: tapEdit)
      }
      self.editors[parameterAddress] = editors
    }

    os_log(.info, log: log, "createEditors - creating bool parameter editors")
    for (parameterAddress, control) in switches {
      os_log(.info, log: log, "createEditors - before BooleanParameterEditor")
      editors[parameterAddress] = [BooleanParameterEditor(parameter: parameters[parameterAddress],
                                                          booleanControl: control)]
    }

    os_log(.info, log: log, "createEditors END")
  }

  @IBAction public func handleKnobValueChange(_ control: Knob) {
    guard let address = control.parameterAddress else { fatalError() }
    handleControlChanged(control, address: address)
  }

  @IBAction public func handleOdd90Change(_ control: Switch) {
    handleControlChanged(control, address: .odd90)
  }

  @IBAction public func handleNegativeFeedbackChange(_ control: Switch) {
    handleControlChanged(control, address: .negativeFeedback)
  }

  private func handleControlChanged(_ control: AUParameterValueProvider, address: ParameterAddress) {
    os_log(.debug, log: log, "controlChanged BEGIN - %d %f", address.rawValue, control.value)

    guard let audioUnit = audioUnit else {
      os_log(.debug, log: log, "controlChanged END - nil audioUnit")
      return
    }

    // When user changes something and a factory preset was active, clear it.
    if let preset = audioUnit.currentPreset, preset.number >= 0 {
      os_log(.debug, log: log, "controlChanged - clearing currentPreset")
      audioUnit.currentPreset = nil
    }

    (editors[address] ?? []).forEach { $0.controlChanged(source: control) }

    os_log(.debug, log: log, "controlChanged END")
  }
}
