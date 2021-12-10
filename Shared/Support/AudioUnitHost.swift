// Copyright © 2021 Brad Howes. All rights reserved.

import AVFoundation
import os

/**
 Delegation protocol for AudioUnitManager class.
 */
public protocol AudioUnitManagerDelegate: AnyObject {
  /**
   Notification that the FilterViewController in the AudioUnitManager has a FilterAudioUnit
   */
  func connected()
}

/**
 Simple hosting container for the FilterAudioUnit when used in an application. Loads the view controller for the
 AudioUnit and then instantiates the audio unit itself. Finally, it wires the AudioUnit with SimplePlayEngine to
 send audio samples to the AudioUnit.
 */
public final class AudioUnitHost {
  private static let log = Logging.logger("AudioUnitHost")
  private var log: OSLog { Self.log }

  private let playEngine = SimplePlayEngine()
  private var _viewController: FilterViewController?

  /// View controller for the AudioUnit interface. NOTE: this is only valid after the delegate `connected` function
  /// is called -- invoked before and it will raise an fatal error.
  public var viewController: FilterViewController { _viewController! }

  /// True if the audio engine is currently playing
  public var isPlaying: Bool { playEngine.isPlaying }

  /// The AudioUnit being managed.
  public var audioUnit: FilterAudioUnit? { _viewController?.audioUnit }

  /// Delegate to signal when everything is wired up.
  public weak var delegate: AudioUnitManagerDelegate? { didSet { signalConnected() } }

  /**
   Create a new instance. Instantiates new FilterAudioUnit and its view controller.

   - parameter interfaceName the name of the storyboard / XIB to load for the UI
   */
  public init(interfaceName: String) {
    createAudioUnit(interfaceName: interfaceName)
  }
}

extension AudioUnitHost {
  private func createAudioUnit(interfaceName: String) {
    os_log(.info, log: log, "createAudioUnit")

    /// Component description that defines the AudioUnit to create. The values must match those found in the
    /// Info.plist used by the app hosts to load the right component.
    let bundle = Bundle.main
    let component = AudioComponentDescription(componentType: FourCharCode(bundle.auComponentSubtype),
                                              componentSubType: FourCharCode(bundle.auComponentSubtype),
                                              componentManufacturer: FourCharCode(bundle.auComponentManufacturer),
                                              componentFlags: 0, componentFlagsMask: 0)
    component.log(log, type: .info)

    // Uff. So for iOS we *need* to register the AUv3 so we can see it now, but we must NOT do so if we are
    // running in macOS or else we will get an error during instantiation.
    //
    #if os(iOS)
    AUAudioUnit.registerSubclass(FilterAudioUnit.self, as: component, name: bundle.auBaseName, version: UInt32.max)
    let options = AudioComponentInstantiationOptions()
    #endif

    // If we are running in macOS we must load the AUv3 in-process in order to be able to use it from within the
    // app sandbox.
    //
    #if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
    #endif

    // Instantiate a new audio unit instance.
    AVAudioUnit.instantiate(with: component, options: options) { avAudioUnit, error in
      guard error == nil, let avAudioUnit = avAudioUnit else {
        fatalError("Could not instantiate audio unit: \(String(describing: error))")
      }

      // We have new instance, now obtain its associated UI view controller. Currently, on iOS this will always
      // fail so we manually load and create the view controller.
      avAudioUnit.auAudioUnit.requestViewController { auViewController in

        // Now we can wire everything up and be on our way.
        // NOTE: we are *not* on the main thread at this point.
        // self.wireAudioUnit(avAudioUnit, viewController: auiewController)
      }
    }
  }

  private func wireAudioUnit(_ avAudioUnit: AVAudioUnit, viewController: FilterViewController) {
    guard let auAudioUnit = avAudioUnit.auAudioUnit as? FilterAudioUnit else {
      fatalError("avAudioUnit.auAudioUnit is nil or wrong type")
    }
    auAudioUnit.viewController = viewController
    _viewController = viewController
    viewController.audioUnit = auAudioUnit
    playEngine.connectEffect(audioUnit: avAudioUnit)
    signalConnected()
  }

  private func signalConnected() {
    guard _viewController?.audioUnit != nil else { return }
    DispatchQueue.main.async { self.delegate?.connected() }
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
  func cleanup() { playEngine.stop() }
}
