# DSP Directory

This directory contains various C++ classes and functions that are useful when working with audio signals.
Nearly all of the functions and classes exist as C++ templates with one parameter being the floating-point type
to use (`double` or `float`).

- [DSP.h](DSP.h) -- collection of simple template functions in the `DSP` namespace for working with unipolar and
  bipolar values. There is also a fast `sin` approximation derived from code in "Designing Audio Effect Plugins
  in C++" by Will C. Pirkle (2019). It has worst-case deviation from std::sin of ~0.0011 which is just fine for
  an low-frequency oscillator (LFO).

- [Biquad](Biquad.h) -- collection of classes in the `Biquad` namespace that allow one to configure a Biquad
  filter for various puposes. Again, much of the math comes from Pirkle's book, but the code is quite different
  in how the features ae combined to generate a Biquad filter.

- [DelayBuffer](DelayBuffer.h) -- simple circular (fixed-size) buffer for audio samples. At present it uses
  linear interpolation when fetching values.

- [InputBuffer](InputBuffer.h) -- buffer manager to understands how to work with CoreAudio's AudioBufferList.
  The buffer is used to hold samples received from an upstream processing node.

- [KernelEventProcessor](KernelEventProcessor.h) -- template class that performs all of the work necessary to
  process samples, MIDI events, and parameter change events. It is to be used as a base class, and it will use
  hand off actual rendering chores to the derived class.

- [LFO](LFO.h) -- simple low-frequency oscillator with three waveforms: sinusoid, triangle, and sawtooth. Based
  on the designed in Pirkle's book/code, this also offers a 90°-advanced version of the main signal
  (`quadPhaseValue`). It also offers a way to save and restore its state, which is useful when working with
  multiple channels that share the same oscillator.

- [ValueChangeDetector](ValueChangeDetector.h) -- a template class that wraps a value (of type `T`) and
  remembers when its value changes. Detection of changed values can be done in a thread-safe manner and
  lock-free manner, for instance from within the audio render thread. (not in use)

- [RampingValueChangeDetector](RampingValueChangeDetector.h) -- a derivation of the above class that offers
  _ramping_ of values between an original value and a new one. When a new value is set, fetching a value will
  not return the new value, but some value between the old and new one. This is usually done to minimize
  discontinuities in signal processing that could result in clicks or pops in the audio stream. (not in use)
