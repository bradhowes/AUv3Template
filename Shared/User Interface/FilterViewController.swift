// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/**
 Controller for the AUv3 filter view.
 */
public final class FilterViewController: AUViewController {
    private let log = Logging.logger("FilterViewController")

    private var viewConfig: AUAudioUnitViewConfiguration!
    private var parameterObserverToken: AUParameterObserverToken?
    private var keyValueObserverToken: NSKeyValueObservation?

    private let logSliderMinValue: Float = 0.0
    private let logSliderMaxValue: Float = 9.0
    private lazy var logSliderMaxValuePower2Minus1 = Float(pow(2, logSliderMaxValue) - 1)

    @IBOutlet weak var depthValueLabel: Label!
    @IBOutlet weak var rateValueLabel: Label!
    @IBOutlet weak var delayValueLabel: Label!
    @IBOutlet weak var feedbackValueLabel: Label!
    @IBOutlet weak var dryMixValueLabel: Label!
    @IBOutlet weak var wetMixValueLabel: Label!

    @IBOutlet weak var depthSlider: Slider!
    @IBOutlet weak var rateSlider: Slider!
    @IBOutlet weak var delaySlider: Slider!
    @IBOutlet weak var feedbackSlider: Slider!
    @IBOutlet weak var dryMixSlider: Slider!
    @IBOutlet weak var wetMixSlider: Slider!

    struct Grouping {
        let label: Label
        let slider: Slider
    }

    var groupings: [FilterParameterAddress: Grouping] = [:]

    public var audioUnit: FilterAudioUnit? {
        didSet {
            performOnMain {
                if self.isViewLoaded {
                    self.connectViewToAU()
                }
            }
        }
    }

    #if os(macOS)
    public override init(nibName: NSNib.Name?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: Bundle(for: type(of: self)))
    }
    #endif

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard audioUnit != nil else { return }
        view.backgroundColor = .black

        groupings[.depth] = Grouping(label: depthValueLabel, slider: depthSlider)
        groupings[.rate] = Grouping(label: rateValueLabel, slider: rateSlider)
        groupings[.delay] = Grouping(label: delayValueLabel, slider: delaySlider)
        groupings[.feedback] = Grouping(label: feedbackValueLabel, slider: feedbackSlider)
        groupings[.dryMix] = Grouping(label: dryMixValueLabel, slider: dryMixSlider)
        groupings[.wetMix] = Grouping(label: wetMixValueLabel, slider: wetMixSlider)

        connectViewToAU()
    }

    public func selectViewConfiguration(_ viewConfig: AUAudioUnitViewConfiguration) {
        guard self.viewConfig != viewConfig else { return }
        self.viewConfig = viewConfig
    }

    @IBAction func depthChanged(_: Slider) { updateParam(.depth) }
    @IBAction func rateChanged(_: Slider) { updateLogScaleParam(.rate) }
    @IBAction func delayChanged(_: Slider) { updateLogScaleParam(.delay) }
    @IBAction func feedbackChanged(_: Slider) { updateParam(.feedback) }
    @IBAction func dryMixChanged(_: Slider) { updateParam(.dryMix) }
    @IBAction func wetMixChanged(_: Slider) { updateParam(.wetMix) }
}

extension FilterViewController: AUAudioUnitFactory {

    /**
     Create a new FilterAudioUnit instance to run in an AVu3 container.

     - parameter componentDescription: descriptions of the audio environment it will run in
     - returns: new FilterAudioUnit
     */
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        os_log(.info, log: log, "creating new audio unit")
        componentDescription.log(log, type: .debug)
        audioUnit = try FilterAudioUnit(componentDescription: componentDescription, options: [.loadOutOfProcess])
        return audioUnit!
    }
}

extension FilterViewController {

    private func connectViewToAU() {
        os_log(.info, log: log, "connectViewToAU")

        guard parameterObserverToken == nil else { return }
        guard let audioUnit = audioUnit else { fatalError("logic error -- nil audioUnit value") }
        guard let paramTree = audioUnit.parameterTree else { fatalError("logic error -- nil parameterTree") }

        keyValueObserverToken = audioUnit.observe(\.allParameterValues) { _, _ in
            self.performOnMain { self.updateDisplay() }
        }

        parameterObserverToken = paramTree.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self else { return }
            os_log(.info, log: self.log, "- parameter value changed: %d %f", address, value)
            self.performOnMain { self.updateDisplay() }
        })

        updateDisplay()
    }

    private func updateDisplay() {
        os_log(.info, log: log, "updateDisplay")

        guard let params = audioUnit?.parameterDefinitions else { return }
        for address in FilterParameterAddress.allCases {
            let param = params[address]
            guard let grouping = groupings[address] else { fatalError()}
            os_log(.info, log: log, "address: %d value: %f", address.rawValue, param.value)
            grouping.label.text = params.formatValue(address, value: param.value)
            switch address {
            case .rate, .delay:
                grouping.slider.minimumValue = logSliderMinValue
                grouping.slider.maximumValue = logSliderMaxValue
                grouping.slider.value = logSliderLocationForParameterValue(param)
            default:
                grouping.slider.minimumValue = param.minValue
                grouping.slider.maximumValue = param.maxValue
                grouping.slider.value = param.value
            }
        }
    }

    private func updateLogScaleParam(_ address: FilterParameterAddress) {
        guard let params = audioUnit?.parameterDefinitions else { return }
        guard let grouping = groupings[address] else { fatalError() }
        os_log(.info, log: log, "updateParam: %d slider value: %f", address.rawValue, grouping.slider.value)
        let value = parameterValueForLogSliderLocation(grouping.slider.value, parameter: params[address])
        grouping.label.text = params.formatValue(address, value: value)
        params[address].value = value
    }

    private func updateParam(_ address: FilterParameterAddress) {
        guard let params = audioUnit?.parameterDefinitions else { return }
        guard let grouping = groupings[address] else { fatalError() }
        os_log(.info, log: log, "updateParam: %d slider value: %f", address.rawValue, grouping.slider.value)
        grouping.label.text = params.formatValue(address, value: grouping.slider.value)
        params[address].value = grouping.slider.value
    }

    private func performOnMain(_ operation: @escaping () -> Void) {
        (Thread.isMainThread ? operation : { DispatchQueue.main.async { operation() } })()
    }
}

extension FilterViewController {

    private func logSliderLocationForParameterValue(_ parameter: AUParameter) -> Float {
        log2(((parameter.value - parameter.minValue) / (parameter.maxValue - parameter.minValue)) *
                logSliderMaxValuePower2Minus1 + 1.0)
    }

    private func parameterValueForLogSliderLocation(_ location: Float, parameter: AUParameter) -> AUValue {
        ((pow(2, location) - 1) / logSliderMaxValuePower2Minus1) * (parameter.maxValue - parameter.minValue) +
            parameter.minValue
    }
}
