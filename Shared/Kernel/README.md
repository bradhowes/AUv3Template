# Kernel Directory

This directory contains the files involved in filtering.

- [BiquadFilter](BiquadFilter.hpp) -- represents the actual low-pass filter and performs the filtering via the
  [vDSP_biquadm](https://developer.apple.com/documentation/accelerate/vdsp/multichannel_biquadratic_iir_filters?language=objc)
  routine in the Apple's [Accelerate framework](https://developer.apple.com/documentation/accelerate?language=objc).

- [FilterDSPKernel](FilterDSPKernel.hpp) -- holds parameters that define the filter (cutoff and resonance) and applies the filter to
  samples during audio unit rendering.

- [FilterDSPKernelAdapter](FilterDSPKernelAdapter.h) -- tiny Objective-C wrapper for the [FilterDSPKernel](FilterDSPKernel.hpp) so that
  Swift can work with it

- [InputBuffer](InputBuffer.hpp) -- manages an [AVAudioPCMBuffer](https://developer.apple.com/documentation/avfaudio/avaudiopcmbuffer)
  that holds audio samples from an upstream node for processing by the filter.

- [KernelEventProcessor](KernelEventProcessor.hpp) -- templated base class that understands how to properly interleave events
  and sample renderings for sample-accurate events. Uses the "curiously recurring template pattern" to do so
  without need of virtual method calls. [FilterDSPKernel](FilterDSPKernel.hpp) derives from this.
