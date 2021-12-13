// Copyright © 2021 Brad Howes. All rights reserved.

import AVFoundation

/**
 Wrapper around AVAudioEngine that manages its wiring with an AVAudioUnit instance.
 */
final class SimplePlayEngine {
  private lazy var bundle = Bundle(for: type(of: self))
  private lazy var bundleIdentifier = bundle.bundleIdentifier!
  private lazy var stateChangeQueue = DispatchQueue(label: bundleIdentifier + ".StateChangeQueue")

  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var activeEffect: AVAudioUnit?

  private lazy var file: AVAudioFile = {
    let filename = "074_acoustic-guitar-strummy2"
    let ext = "wav"
    guard let url = bundle.url(forResource: filename, withExtension: ext) else {
      fatalError("\(filename).\(ext) missing from bundle")
    }
    do {
      return try AVAudioFile(forReading: url)
    } catch {
      fatalError("failed to create AVAudioFile from url - \(url)")
    }
  }()

  /// True if engine is currently playing the audio file.
  public var isPlaying: Bool { player.isPlaying }

  /**
   Create new audio processing setup, with an audio file player connected directly to the mixer for the main
   output device.
   */
  init() {
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
    engine.prepare()
  }
}

extension SimplePlayEngine {

  /**
   Start playback of the audio file player.
   */
  public func start() {
    stateChangeQueue.sync {
      guard !player.isPlaying else { return }
      updateAudioSession(active: true)
      beginLoop()
      do {
        try engine.start()
      } catch {
        fatalError("failed to start AVAudioEngine")
      }
      player.play()
    }
  }

  /**
   Stop playback of the audio file player.
   */
  public func stop() {
    stateChangeQueue.sync {
      guard player.isPlaying else { return }
      player.stop()
      engine.stop()
      updateAudioSession(active: false)
    }
  }

  /**
   Toggle the playback of the audio file player.

   @returns state of the player
   */
  public func startStop() -> Bool {
    if player.isPlaying { stop() } else { start() }
    return player.isPlaying
  }

  /**
   Install an effect AudioUnit between an audio source and the main output mixer. If there was a previous effect
   installed it is removed from the signal chain. If the sound resource was playing it will be resumed after the
   new effect is installed.

   @param audioUnit the audio unit to install
   @param completion closure to call when finished
   */
  public func connectEffect(audioUnit: AVAudioUnit, completion: @escaping (() -> Void) = {}) {
    defer { completion() }
    pauseWhile {
      disconnectEffect()
      activeEffect = audioUnit
      engine.attach(audioUnit)
      engine.connect(player, to: audioUnit, format: file.processingFormat)
      engine.connect(audioUnit, to: engine.mainMixerNode, format: file.processingFormat)
    }
  }

  /**
   Uninstall a previously-installed effect AudioUnit.
   */
  public func disconnectEffect() {
    guard let previous = activeEffect else { return }
    activeEffect = nil
    pauseWhile {
      engine.disconnectNodeInput(previous)
      engine.disconnectNodeInput(engine.mainMixerNode)
      engine.detach(previous)
      engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
    }
  }
}

private extension SimplePlayEngine {

  /**
   If player is currently playing audio pause it the execution of the given block and then resume it after the block
   is done.

   - parameter block: closure to execute while player is paused
   */
  private func pauseWhile(_ block: () -> Void) {
    let wasPlaying = player.isPlaying
    if wasPlaying { player.pause() }
    block()
    if wasPlaying { player.play() }
  }

  private func updateAudioSession(active: Bool) {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default)
      try session.setActive(active)
    } catch {
      fatalError("Could not set Audio Session active \(active). error: \(error).")
    }
    #endif
  }

  /**
   Start playing the audio resource and play it again once it is done.
   */
  private func beginLoop() {
    player.scheduleFile(file, at: nil) {
      self.stateChangeQueue.async {
        if self.player.isPlaying {
          self.beginLoop()
        }
      }
    }
  }
}
