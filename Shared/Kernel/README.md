# Kernel Directory

This directory contains the files involved in doing the audio filtering and digital signal processing (DSP).

- [DSP](DSP) -- contains various C++ classes and functions that are useful when working with audio signals.

- [__NAME__Kernel](__NAME__Kernel.h) -- holds the main processing block that acts on individual audio samples.

- [__NAME__KernelAdapter](__NAME__KernelAdapter.h) -- tiny Objective-C wrapper for the
  [__NAME__PKernel](__NAME__Kernel.h) so that Swift can communicate with it. Note that most of the integration
  work is done elsewhere via AUParameter values. This adapter is mainly in charge of creating a new
  __NAME__Kernel and forwarding rendering requests to it.
