// Changes: Copyright © 2020 Brad Howes. All rights reserved.
// Original: See LICENSE folder for this sample’s licensing information.

import AVFoundation
import os.log

/**
 Errors that can come from AudioUnitHost.
 */
public enum AudioUnitHostError: Error {
  /// Unexpected nil AUAudioUnit (most likely never can happen)
  case nilAudioUnit
  /// Unexpected nil ViewController from AUAudioUnit request
  case nilViewController
  /// Failed to locate component matching given AudioComponentDescription
  case componentNotFound
  /// Error from Apple framework (CoreAudio, AVFoundation, etc.)
  case framework(error: Error)
  /// String describing the error case.
  public var description: String {
    switch self {
    case .nilAudioUnit: return "Failed to obtain a usable audio unit instance."
    case .nilViewController: return "Failed to obtain a usable view controller from the instantiated audio unit."
    case .componentNotFound: return "Failed to locate the right AUv3 component to instantiate."
    case .framework(let err): return "Framework error: \(err.localizedDescription)"
    }
  }
}

/**
 Delegation protocol for AudioUnitHost class.
 */
public protocol AudioUnitHostDelegate: AnyObject {
  /**
   Notification that the UIViewController in the AudioUnitHost has a wired AUAudioUnit
   */
  func connected(audioUnit: AUAudioUnit, viewController: ViewController)

  /**
   Notification that there was a problem instantiating the audio unit or its view controller

   - parameter error: the error that was encountered
   */
  func failed(error: AudioUnitHostError)
}

/**
 Simple hosting container for the FilterAudioUnit when used in an application. Loads the view controller for the
 AudioUnit and then instantiates the audio unit itself. Finally, it wires the AudioUnit with SimplePlayEngine to
 send audio samples to the AudioUnit. Note that this class has no knowledge of any classes other than what Apple
 provides.
 */
public final class AudioUnitHost {
  private let log = Logging.logger("AudioUnitHost")

  /// AudioUnit controlled by the view controller
  public private(set) var audioUnit: AUAudioUnit?

  /// View controller for the AudioUnit interface
  public private(set) var viewController: ViewController?

  /// True if the audio engine is currently playing
  public var isPlaying: Bool { playEngine.isPlaying }

  /// Delegate to signal when everything is wired up.
  public weak var delegate: AudioUnitHostDelegate? { didSet { notifyDelegate() } }

  private let lastStateKey = "lastStateKey"
  private let lastPresetNumberKey = "lastPresetNumberKey"

  private let playEngine = SimplePlayEngine()
  private var isRestoring: Bool = false
  private let locateQueue = DispatchQueue(label: Bundle.bundleID + ".LocateQueue", qos: .userInitiated)
  private let componentDescription: AudioComponentDescription

  private var notificationObserverToken: NSObjectProtocol?
  private var creationError: AudioUnitHostError? { didSet { notifyDelegate() } }
  private var detectionTimer: Timer?

  /**
   Create a new instance that will hopefully create a new AUAudioUnit and a view controller for its control view.

   - parameter componentDescription: the definition of the AUAudioUnit to create
   */
  public init(componentDescription: AudioComponentDescription) {
    self.componentDescription = componentDescription
    componentDescription.log(log, type: .info)
    locate()
  }

  /**
   Use AVAudioUnitComponentManager to locate the AUv3 component we want. This is done asynchronously in the background.
   If the component we want is not found, start listening for notifications from the AVAudioUnitComponentManager for
   updates and try again.
   */
  private func locate() {
    os_log(.info, log: log, "locate")
    locateQueue.async { [weak self] in
      guard let self = self else { return }

      let description = AudioComponentDescription(componentType: self.componentDescription.componentType,
                                                  componentSubType: 0,
                                                  componentManufacturer: 0,
                                                  componentFlags: 0,
                                                  componentFlagsMask: 0)

      let components = AVAudioUnitComponentManager.shared().components(matching: description)
      os_log(.info, log: self.log, "locate: found %d", components.count)

      for each in components {
        each.audioComponentDescription.log(self.log, type: .info)
        if each.audioComponentDescription.componentManufacturer == self.componentDescription.componentManufacturer,
           each.audioComponentDescription.componentType == self.componentDescription.componentType,
           each.audioComponentDescription.componentSubType == self.componentDescription.componentSubType
        {
          os_log(.info, log: self.log, "found match")
          DispatchQueue.main.async {
            self.createAudioUnit(each.audioComponentDescription)
          }
          return
        }
      }

      DispatchQueue.performOnMain {
        self.checkAgain()
      }
    }
  }

  /**
   Begin listening for updates from the AVAudioUnitComponentManager. When we get one, stop listening and attempt to
   locate the AUv3 component we want.
   */
  private func checkAgain() {
    os_log(.info, log: log, "checkAgain")
    let center = NotificationCenter.default

    detectionTimer?.invalidate()
    detectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
      self.creationError = AudioUnitHostError.componentNotFound
    }

    notificationObserverToken = center.addObserver(
      forName: AVAudioUnitComponentManager.registrationsChangedNotification, object: nil, queue: nil
    ) { [weak self] _ in
      guard let self = self else { return }
      os_log(.info, log: self.log, "checkAgain: notification")
      let token = self.notificationObserverToken!
      self.notificationObserverToken = nil
      center.removeObserver(token)
      self.detectionTimer?.invalidate()
      self.locate()
    }
  }

  /**
   Create the desired component using the AUv3 API
   */
  private func createAudioUnit(_ componentDescription: AudioComponentDescription) {
    os_log(.info, log: log, "createAudioUnit")
    guard audioUnit == nil else { return }

    #if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
    #else
    let options: AudioComponentInstantiationOptions = .loadOutOfProcess
    #endif

    AVAudioUnit.instantiate(with: componentDescription, options: options) { [weak self] avAudioUnit, error in
      guard let self = self else { return }
      if let error = error {
        os_log(.error, log: self.log, "createAudioUnit: error - %{public}s", error.localizedDescription)
        self.creationError = .framework(error: error)
        return
      }

      guard let avAudioUnit = avAudioUnit else {
        os_log(.error, log: self.log, "createAudioUnit: nil avAudioUnit")
        self.creationError = AudioUnitHostError.nilAudioUnit
        return
      }

      DispatchQueue.main.async {
        self.createViewController(avAudioUnit)
      }
    }
  }

  /**
   Create the component's view controller to embed in the host view.

   - parameter avAudioUnit: the AVAudioUnit that was instantiated
   */
  private func createViewController(_ avAudioUnit: AVAudioUnit) {
    os_log(.info, log: log, "createViewController")
    avAudioUnit.auAudioUnit.requestViewController { [weak self] controller in
      guard let self = self else { return }
      guard let controller = controller else {
        self.creationError = AudioUnitHostError.nilViewController
        return
      }
      os_log(.info, log: self.log, "view controller type - %{public}s", String(describing: type(of: controller)))
      self.wireAudioUnit(avAudioUnit, controller)
    }
  }

  /**
   Finalize creation of the AUv3 component. Connect to the audio engine and notify the main view controller that
   everything is done.

   - parameter avAudioUnit: the audio unit that was created
   - parameter viewController: the view controller that was created
   */
  private func wireAudioUnit(_ avAudioUnit: AVAudioUnit, _ viewController: ViewController) {
    audioUnit = avAudioUnit.auAudioUnit
    self.viewController = viewController

    playEngine.connectEffect(audioUnit: avAudioUnit)
    notifyDelegate()
  }

  private func notifyDelegate() {
    os_log(.info, log: log, "notifyDelegate")
    if let creationError = creationError {
      os_log(.info, log: log, "error: %{public}s", creationError.localizedDescription)
      DispatchQueue.performOnMain { self.delegate?.failed(error: creationError) }
    } else if let audioUnit = audioUnit, let viewController = viewController {
      os_log(.info, log: log, "success")
      DispatchQueue.performOnMain { self.delegate?.connected(audioUnit: audioUnit, viewController: viewController) }
    }
  }
}

public extension AudioUnitHost {
  private var noCurrentPresetNumber: Int { Int.max }

  /**
   Save the current state of the AudioUnit to UserDefaults for future restoration.
   */
  func save() {
    guard !isRestoring else { return }

    if let lastState = audioUnit?.fullStateForDocument {
      UserDefaults.standard.set(lastState, forKey: lastStateKey)
    } else {
      UserDefaults.standard.removeObject(forKey: lastStateKey)
    }

    let lastPresetNumber = audioUnit?.currentPreset?.number ?? noCurrentPresetNumber
    UserDefaults.standard.set(lastPresetNumber, forKey: lastPresetNumberKey)
  }

  /**
   Restore the state of the AudioUnit using values found in UserDefaults.
   */
  func restore() {
    guard let audioUnit = audioUnit else { fatalError() }
    guard !isRestoring else { fatalError() }

    isRestoring = true
    defer {
      isRestoring = false
    }

    if let lastState = UserDefaults.standard.dictionary(forKey: lastStateKey) {
      audioUnit.fullStateForDocument = lastState
    }

    guard let lastPresetNumber = UserDefaults.standard.object(forKey: lastPresetNumberKey) as? NSNumber else { return }
    let presetNumber = lastPresetNumber.intValue
    guard presetNumber != noCurrentPresetNumber else {
      audioUnit.currentPreset = nil
      return
    }

    audioUnit.currentPreset = (presetNumber >= 0
      ? audioUnit.factoryPresetsArray[presetNumber]
      : audioUnit.userPresets.first(where: { $0.number == presetNumber }))
  }
}

public extension AudioUnitHost {
  /**
   Start/stop audio engine

   - returns: true if playing
   */
  @discardableResult
  func togglePlayback() -> Bool { playEngine.startStop() }

  /**
   The world is being torn apart. Stop any asynchronous eventing from happening in the future.
   */
  func cleanup() {
    playEngine.stop()
  }
}
