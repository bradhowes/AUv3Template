// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import AVFoundation
import CoreAudioKit
import os

/**
 Derivation of AUAudioUnit that provides a Swift container for the C++ __NAME__Kernel (by way of the Obj-C
 __NAME__KernelAdapter). Also provides for factory presets and preset management. The actual filtering logic
 resides in the __NAME__Kernel class.
 */
public final class FilterAudioUnit: AUAudioUnit {
    private static let log = Logging.logger("FilterAudioUnit")
    private var log: OSLog { Self.log }

    public enum Failure: Swift.Error {
        case statusError(OSStatus)
        case unableToInitialize(String)
    }

    /// Component description that matches this AudioUnit. The values must match those found in the Info.plist
    /// Used by the app hosts to load the right component.
    public static let componentDescription: AudioComponentDescription = {
        let bundle = Bundle(for: FilterAudioUnit.self)
        return AudioComponentDescription(
            componentType: FourCharCode(stringLiteral: bundle.auComponentType),
            componentSubType: FourCharCode(stringLiteral: bundle.auComponentSubtype),
            componentManufacturer: FourCharCode(stringLiteral: bundle.auComponentManufacturer),
            componentFlags: 0,
            componentFlagsMask: 0
        )
    }()

    /// Name of the component
    public static let componentName = Bundle(for: FilterAudioUnit.self).auComponentName
    /// The associated view controller for the audio unit that shows the controls
    public weak var viewController: FilterViewController?
    /// Runtime parameter definitions for the audio unit
    public lazy var parameterDefinitions: AudioUnitParameters = AudioUnitParameters(parameterHandler: kernel)
    /// Support one input bus
    override public var inputBusses: AUAudioUnitBusArray { _inputBusses }
    /// Support one output bus
    override public var outputBusses: AUAudioUnitBusArray { _outputBusses }
    /// Parameter tree containing filter parameter values
    override public var parameterTree: AUParameterTree? {
        get { parameterDefinitions.parameterTree }
        set { fatalError("attempted to set new parameterTree") }
    }

    /// Factory presets for the filter
    override public var factoryPresets: [AUAudioUnitPreset] { _factoryPresets }
    /// Announce support for user presets as well
    override public var supportsUserPresets: Bool { true }
    /// Preset get/set
    override public var currentPreset: AUAudioUnitPreset? {
        get {
            os_log(.info, log: log, "get currentPreset - %{public}s", _currentPreset.descriptionOrNil)
            return _currentPreset
        }
        set {
            os_log(.info, log: log, "set currentPreset - %{public}s", newValue.descriptionOrNil)
            guard let preset = newValue else {
                _currentPreset = nil
                return
            }

            if preset.number >= 0 {
                os_log(.info, log: log, "factoryPreset %d", preset.number)
                let settings = factoryPresetValues[preset.number]
                _currentPreset = preset
                os_log(.info, log: log, "updating parameters")
                parameterDefinitions.setValues(settings.preset)
            }
            else {
                os_log(.info, log: log, "userPreset %d", preset.number)
                if let state = try? presetState(for: preset) {
                    os_log(.info, log: log, "state: %{public}s", state.debugDescription)
                    fullState = state
                    _currentPreset = preset
                }
            }
        }
    }

    override public var fullState: [String : Any]? {
        get {
            os_log(.info, log: log, "fullState GET")
            var value = super.fullState ?? [String: Any]()
            if let preset = _currentPreset {
                value[kAUPresetNameKey] = preset.name
                value[kAUPresetNumberKey] = preset.number
            }
            os_log(.info, log: log, "value: %{public}s", value.description)
            return value
        }
        set {
            os_log(.info, log: log, "fullState SET")
            os_log(.info, log: log, "value: %{public}s", newValue.descriptionOrNil)
            super.fullState = newValue
            if let newValue = newValue,
               let name = newValue[kAUPresetNameKey] as? String,
               let number = newValue[kAUPresetNumberKey] as? NSNumber {
                os_log(.info, log: log, "name %{public}s number %d", name, number.intValue)
                currentPreset = AUAudioUnitPreset(number: number.intValue, name: name)
            }
        }
    }

    override public var shouldBypassEffect: Bool { didSet { kernel.setBypass(shouldBypassEffect); }}

    override public var fullStateForDocument: [String : Any]? {
        get {
            os_log(.info, log: log, "fullStateForDocument GET")
            let value = super.fullStateForDocument
            os_log(.info, log: log, "value: %{public}s", value.descriptionOrNil)
            return value
        }
        set {
            os_log(.info, log: log, "fullStateForDocument SET")
            os_log(.info, log: log, "value: %{public}s", newValue.descriptionOrNil)
            super.fullStateForDocument = newValue
       }
    }

    /// Announce that the filter can work directly on upstream sample buffers
    override public var canProcessInPlace: Bool { true }

    /// Initial sample rate
    private let sampleRate: Double = 44100.0
    /// Maximum number of channels to support
    private let maxNumberOfChannels: UInt32 = 8
    /// Maximum frames to render
    private let maxFramesToRender: UInt32 = 512
    /// Objective-C bridge into the C++ kernel
    private let kernel = __NAME__KernelAdapter(Bundle.main.auBaseName,
                                             maxDelayMilliseconds: AudioUnitParameters.maxDelayMilliseconds)

    private let factoryPresetValues:[(name: String, preset: FilterPreset)] = [
        ("Flangie", FilterPreset(depth: 100, rate: 0.14, delay: 0.72, feedback: 50, dryMix: 50, wetMix: 50)),
        ("Sweeper", FilterPreset(depth: 100, rate: 0.14, delay: 1.51, feedback: 80, dryMix: 50, wetMix: 50)),
        ("Lord Tremolo", FilterPreset(depth: 100, rate: 8.6, delay: 0.07, feedback: 90, dryMix: 0, wetMix: 100))
    ]

    private var _currentPreset: AUAudioUnitPreset? {
        didSet { os_log(.debug, log: log, "* _currentPreset name: %{public}s", _currentPreset.descriptionOrNil) }
    }

    private lazy var _factoryPresets = factoryPresetValues.enumerated().map {
        AUAudioUnitPreset(number: $0, name: $1.name)
    }

    private var inputBus: AUAudioUnitBus
    private var outputBus: AUAudioUnitBus

    private lazy var _inputBusses: AUAudioUnitBusArray = { AUAudioUnitBusArray(audioUnit: self, busType: .input,
                                                                               busses: [inputBus]) }()
    private lazy var _outputBusses: AUAudioUnitBusArray = { AUAudioUnitBusArray(audioUnit: self, busType: .output,
                                                                                busses: [outputBus]) }()
    /**
     Crete a new audio unit asynchronously.

     - parameter componentDescription: the component to instantiate
     - parameter options: options for instantiation
     - parameter completionHandler: closure to invoke upon creation or error
     */
    override public class func instantiate(with componentDescription: AudioComponentDescription,
                                           options: AudioComponentInstantiationOptions = [],
                                           completionHandler: @escaping (AUAudioUnit?, Error?) -> Void) {
        do {
            let auAudioUnit = try FilterAudioUnit(componentDescription: componentDescription, options: options)
            completionHandler(auAudioUnit, nil)
        } catch {
            completionHandler(nil, error)
        }
    }

    /**
     Construct new instance, throwing exception if there is an error doing so.

     - parameter componentDescription: the component to instantiate
     - parameter options: options for instantiation
     */
    override public init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        // Start with the default format. Host or downstream AudioUnit can change the format of the input/output bus
        // objects later between calls to allocateRenderResources().
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            os_log(.error, log: Self.log, "failed to create AVAudioFormat format")
            throw Failure.unableToInitialize(String(describing: AVAudioFormat.self))
        }

        os_log(.debug, log: Self.log, "format: %{public}s", format.description)
        inputBus = try AUAudioUnitBus(format: format)
        inputBus.maximumChannelCount = maxNumberOfChannels

        os_log(.debug, log: Self.log, "creating output bus")
        outputBus = try AUAudioUnitBus(format: format)
        outputBus.maximumChannelCount = maxNumberOfChannels

        try super.init(componentDescription: componentDescription, options: options)

        os_log(.debug, log: log, "type: %{public}s, subtype: %{public}s, manufacturer: %{public}s flags: %x",
               componentDescription.componentType.stringValue,
               componentDescription.componentSubType.stringValue,
               componentDescription.componentManufacturer.stringValue,
               componentDescription.componentFlags)

        maximumFramesToRender = maxFramesToRender
        currentPreset = factoryPresets.first

        // This really should be postponed until allocateRenderResources is called. However, for some weird reason
        // internalRenderBlock is fetched before allocateRenderResources() gets called, so we need to preflight here.
        kernel.startProcessing(format, maxFramesToRender: maxFramesToRender)
    }

    /**
     Take notice of input/output bus formats and prepare for rendering. If there are any errors getting things ready,
     routine should `setRenderResourcesAllocated(false)`.
     */
    override public func allocateRenderResources() throws {
        os_log(.info, log: log, "allocateRenderResources")
        os_log(.debug, log: log, "inputBus format: %{public}s", inputBus.format.description)
        os_log(.debug, log: log, "outputBus format: %{public}s", outputBus.format.description)
        os_log(.debug, log: log, "maximumFramesToRender: %d", maximumFramesToRender)

        if outputBus.format.channelCount != inputBus.format.channelCount {
            os_log(.error, log: log, "unequal channel count")
            setRenderResourcesAllocated(false)
            throw Failure.statusError(kAudioUnitErr_FailedInitialization)
        }

        // Communicate to the kernel the new formats being used
        kernel.startProcessing(inputBus.format, maxFramesToRender: maximumFramesToRender)

        try super.allocateRenderResources()
    }

    /**
     Rendering has stopped -- tear down stuff that was supporting it.
     */
    override public func deallocateRenderResources() {
        os_log(.debug, log: log, "before super.deallocateRenderResources")
        kernel.stopProcessing()
        super.deallocateRenderResources()
        os_log(.debug, log: log, "after super.deallocateRenderResources")
    }

    override public var internalRenderBlock: AUInternalRenderBlock {
        os_log(.info, log: log, "internalRenderBlock")

        // Local values to capture in the closure that will be returned
        let maximumFramesToRender = self.maximumFramesToRender
        let kernel = self.kernel

        return { _, timestamp, frameCount, outputBusNumber, outputData, events, pullInputBlock in
            guard outputBusNumber == 0 else { return kAudioUnitErr_InvalidParameterValue }
            guard frameCount <= maximumFramesToRender else { return kAudioUnitErr_TooManyFramesToProcess }
            guard let pullInputBlock = pullInputBlock else { return kAudioUnitErr_NoConnection }
            return kernel.process(UnsafeMutablePointer(mutating: timestamp), frameCount: frameCount, output: outputData,
                                  events: UnsafeMutablePointer(mutating: events), pullInputBlock: pullInputBlock)
        }
    }

    override public func parametersForOverview(withCount: Int) -> [NSNumber] {
        parameterDefinitions.parameters[0..<withCount].map { NSNumber(value: $0.address) }
    }

    override public func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) ->
    IndexSet {
        IndexSet(integersIn: 0..<availableViewConfigurations.count)
    }

    override public func select(_ viewConfiguration: AUAudioUnitViewConfiguration) {
        viewController?.selectViewConfiguration(viewConfiguration)
    }
}
