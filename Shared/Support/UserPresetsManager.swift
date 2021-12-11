// Copyright © 2021 Apple. All rights reserved.

import AudioToolbox
import Foundation

/**
 Subset of AUAudioUnit functionality that is used by UserPresetsManager.
 */
public protocol AUAudioUnitPresetsFacade: AnyObject {

  /// Obtain an array of factory presets that is never nil.
  var factoryPresetsNonNil: [AUAudioUnitPreset] { get }

  /// Obtain an array of user presets.
  var userPresets: [AUAudioUnitPreset] { get }

  /// Currently active preset (user or factory). May be nil.
  var currentPreset: AUAudioUnitPreset? { get set }

  /// Save the given user preset.
  func saveUserPreset(_ preset: AUAudioUnitPreset) throws

  /// Delete the given user preset.
  func deleteUserPreset(_ preset: AUAudioUnitPreset) throws
}

extension AUAudioUnit: AUAudioUnitPresetsFacade {

  /// Variation of `factoryPresets` that is never nil.
  public var factoryPresetsNonNil: [AUAudioUnitPreset] { factoryPresets ?? [] }
}

/**
 Manager of user presets for the AUv3 component. Supports creation, renaming, and deletion. Also, manages the
 `currentPreset` attribute of the component.
 */
public class UserPresetsManager {

  /// The slice of the AUv3 component that the manager works with
  public let audioUnit: AUAudioUnitPresetsFacade

  /// The (user) presets straight from the component
  public var presets: [AUAudioUnitPreset] { audioUnit.userPresets }

  /// The (user) presets from the component ordered by preset number in descending order (-1 first)
  public var presetsOrderedByNumber: [AUAudioUnitPreset] { presets.sorted { $0.number > $1.number } }

  /// The (user) presets from the component ordered by preset name in ascending order
  public var presetsOrderedByName: [AUAudioUnitPreset] {
    presets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  /**
   Create new instance for the given AUv3 component

   - parameter audioUnit: AUv3 component
   */
  public init(for audioUnit: AUAudioUnitPresetsFacade) {
    self.audioUnit = audioUnit
  }

  /**
   Locate the user preset with the given name

   - parameter name: the name to look for
   - returns: the preset that was found or nil
   */
  public func find(name: String) -> AUAudioUnitPreset? {
    presets.first(where: { $0.name == name })
  }

  /**
   Locate the user preset with the given number

   - parameter number: the number to look for
   - returns: the preset that was found or nil
   */
  public func find(number: Int) -> AUAudioUnitPreset? {
    presets.first(where: { $0.number == number })
  }

  /// Clear the `currentPreset` attribute of the component.
  public func clearCurrentPreset() {
    audioUnit.currentPreset = nil
  }

  /**
   Make the first user preset with the given name the current preset.

   - parameter name: the name to look for
   */
  public func makeCurrentPreset(name: String) {
    audioUnit.currentPreset = find(name: name)
  }

  /**
   Make the first user preset with the given preset number the current preset. NOTE: unlike the 'name' version, this
   will access factory presets when the number is non-negative.

   - parameter number: the number to look for
   */
  public func makeCurrentPreset(number: Int) {
    if number >= 0 {
      audioUnit.currentPreset = audioUnit.factoryPresetsNonNil[validating: number]
    } else {
      audioUnit.currentPreset = find(number: number)
    }
  }

  /**
   Create a new user preset under the given name. The number assigned to the preset is the smallest negative value
   that is not being used by any other user preset. Makes the new preset current.

   - parameter name: the name to use for the preset
   - throws exception from AUAudioUnit
   */
  public func create(name: String) throws {
    let preset = AUAudioUnitPreset(number: nextNumber, name: name)
    try audioUnit.saveUserPreset(preset)
    audioUnit.currentPreset = preset
  }

  /**
   Update a given user preset by saving it again, presumably with new state from the AUv3 component.

   - parameter preset: the existing preset to save
   - throws exception from AUAudioUnit
   */
  public func update(preset: AUAudioUnitPreset) throws {
    guard preset.number < 0 else { return }
    let preset = AUAudioUnitPreset(number: preset.number, name: preset.name)
    try audioUnit.saveUserPreset(preset)
    audioUnit.currentPreset = preset
  }

  /**
   Change the name of the _current_ preset to a new value.

   - parameter name: the new name to use
   - throws exception from AUAudioUnit
   */
  public func renameCurrent(to name: String) throws {
    guard let old = audioUnit.currentPreset, old.number < 0 else { return }
    let new = AUAudioUnitPreset(number: old.number, name: name)
    try audioUnit.deleteUserPreset(old)
    try audioUnit.saveUserPreset(new)
    audioUnit.currentPreset = new
  }

  /**
   Delete the existing user preset that is currently active.

   - throws exception from AUAudioUnit
   */
  public func deleteCurrent() throws {
    guard let preset = audioUnit.currentPreset, preset.number < 0 else { return }
    audioUnit.currentPreset = nil
    try audioUnit.deleteUserPreset(AUAudioUnitPreset(number: preset.number, name: preset.name))
  }

  /// Obtain the smallest user preset number that is not being used by any other preset.
  public var nextNumber: Int {
    let ordered = presetsOrderedByNumber
    var number = ordered.first?.number ?? -1
    for entry in ordered {
      if entry.number != number {
        break
      }
      number -= 1
    }

    return number
  }
}

public extension RandomAccessCollection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  /// - complexity: O(1)
  /// https://stackoverflow.com/a/68453929/629836
  subscript(validating index: Index) -> Element? {
    index >= startIndex && index < endIndex ? self[index] : nil
  }
}
