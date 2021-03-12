# User Interface

Contains nearly all of the code used to generate the visuals for the AUv3 plugin. It follows a design found in
an example project from Apple (see [TypeAliases.swift](TypeAliases.swift)) but expanded on to support additional
controls and features.

- [FilterViewController](FilterViewController.swift) -- the common view controller that manages the views in the
  macOS and iOS plugins. For a purely graphical representation, this makes sense, but there are perhaps too many
  `#if` conditionals now to make keeping this in one file.

- [Knob_iOS](Knob_iOS.swift) -- a custom UIControl that draws a knob as a circular arc. Relies entirely on
  CALayer for doing the drawing.

- [Knob_macOS](Knob_macOS.swift) -- a custom NSControl that draws a knob as a circular arc. Relies entirely on
  CALayer for doing the drawing. This was at one point combined with the iOS version, but it became very
  difficult to not mess up one platform while fixing something on another one.

- [AUParameterControl](AUParameterControl.swift) -- interface that defines the actions for a UI control that
  manages an AUParameter value. Used within `FilterViewController` to work with generic controls.

- [KnobController](KnobController.swift) -- Associates an AUParameter with a Knob / label pair. Normally the
  label shows the name of the parameter, but when the knob value changes, the label indicates the current value
  of the parameter. On iOS, tapping the label allows for editing the value via the keyboard. On macOS, clicking
  on the label makes it editable to achieve the same thing.

- [SwitchController](SwitchController.swift) -- Associates a (boolean) AUParameter with a UISwitch/NSSwitch.
