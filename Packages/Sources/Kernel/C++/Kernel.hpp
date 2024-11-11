// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <string>
#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BusBuffers.hpp"
#import "DSPHeaders/DelayBuffer.hpp"
#import "DSPHeaders/EventProcessor.hpp"
#import "DSPHeaders/LFO.hpp"
#import "DSPHeaders/Parameters/Bool.hpp"
#import "DSPHeaders/Parameters/Milliseconds.hpp"
#import "DSPHeaders/Parameters/Percentage.hpp"

/**
 The audio processing kernel that generates a "flange" effect by combining an audio signal with a slightly delayed copy
 of itself. The delay value oscillates at a defined frequency which causes the delayed audio to vary in pitch due to it
 being sped up or slowed down.
 */
class Kernel : public DSPHeaders::EventProcessor<Kernel> {
public:
  using super = DSPHeaders::EventProcessor<Kernel>;
  friend super;

  /**
   Construct new kernel

   @param name the name to use for logging purposes.
   */
  Kernel(std::string name) noexcept : super(), name_{name}, log_{os_log_create(name_.c_str(), "Kernel")}
  {
    os_log_debug(log_, "constructor");
    registerParameter(delay_);
    registerParameter(depth_);
    registerParameter(feedback_);
    registerParameter(wetMix_);
    registerParameter(dryMix_);
    registerParameter(negativeFeedback_);
    registerParameter(odd90_);
  }

  /**
   Update kernel and buffers to support the given format and channel count

   @param format the audio format to render
   @param maxFramesToRender the maximum number of samples we will be asked to render in one go
   @param maxDelayMilliseconds the max number of milliseconds of audio samples to keep in delay buffer
   */
  void setRenderingFormat(NSInteger busCount, AVAudioFormat* format, AUAudioFrameCount maxFramesToRender,
                          double maxDelayMilliseconds) noexcept {
    super::setRenderingFormat(busCount, format, maxFramesToRender);
    initialize(format.channelCount, format.sampleRate, maxDelayMilliseconds);
  }

private:
  using DelayLine = DSPHeaders::DelayBuffer<AUValue>;
  using LFO = DSPHeaders::LFO<AUValue>;

  void initialize(int channelCount, double sampleRate, double maxDelayMilliseconds) noexcept {
    maxDelayMilliseconds_ = maxDelayMilliseconds;
    samplesPerMillisecond_ = sampleRate / 1000.0;

    lfo_.setSampleRate(sampleRate);
    lfo_.setWaveform(LFOWaveform::triangle);

    auto size = maxDelayMilliseconds * samplesPerMillisecond_ + 1;
    delayLines_.clear();
    os_log_debug(log_, "delay sample size: %f", size);
    for (auto index = 0; index < channelCount; ++index) {
      delayLines_.emplace_back(size);
    }
  }

  /**
   Set a paramete value from within the render loop.

   @param address the parameter to change
   @param value the new value to use
   @param duration the ramping duration to transition to the new value
   */
  bool doSetImmediateParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) noexcept;

  /**
   Set a paramete value from the UI via the parameter tree. Will be recognized and handled in the next render pass.

   @param address the parameter to change
   @param value the new value to use
   */
  bool doSetPendingParameterValue(AUParameterAddress address, AUValue value) noexcept;

  /**
   Get the paramete value last set in the render thread. NOTE: this does not account for any ramping that might be in
   effect.

   @param address the parameter to access
   @returns parameter value
   */
  AUValue doGetImmediateParameterValue(AUParameterAddress address) const noexcept;

  /**
   Get the paramete value last set by the UI / parameter tree. NOTE: this does not account for any ramping that might
   be in effect.

   @param address the parameter to access
   @returns parameter value
   */
  AUValue doGetPendingParameterValue(AUParameterAddress address) const noexcept;

  void writeSample(DSPHeaders::BusBuffers ins, DSPHeaders::BusBuffers outs, AUValue evenTap, AUValue oddTap,
                   AUValue feedback, AUValue wetMix, AUValue dryMix) noexcept {
    for (int channel = 0; channel < ins.size();  ++channel) {
      auto inputSample = *ins[channel]++;
      auto delayedSample = delayLines_[channel].read((channel & 1) ? oddTap : evenTap);
      delayLines_[channel].write(inputSample + feedback * delayedSample);
      *outs[channel]++ = wetMix * delayedSample + dryMix * inputSample;
    }
  }

  std::tuple<AUValue, AUValue> calcSingleTap(AUValue nominalMilliseconds, AUValue displacementMilliseconds) noexcept {
    auto tap = (nominalMilliseconds + lfo_.value() * displacementMilliseconds) * samplesPerMillisecond_;
    lfo_.increment();
    return {tap, tap};
  }

  std::tuple<AUValue, AUValue> calcDoubleTap(AUValue nominalMilliseconds, AUValue displacementMilliseconds) noexcept {
    auto evenTap = (nominalMilliseconds + lfo_.value() * displacementMilliseconds) * samplesPerMillisecond_;
    auto oddTap = (nominalMilliseconds + lfo_.quadPhaseValue() * displacementMilliseconds) * samplesPerMillisecond_;
    lfo_.increment();
    return {evenTap, oddTap};
  }

  std::tuple<AUValue, AUValue> calcCenterVariance(AUValue delay, AUValue depth) noexcept {
    auto variance = (maxDelayMilliseconds_ - delay) * depth / 2.0;
    auto center = delay + variance;
    return {center, variance};
  }

  void doRendering(NSInteger outputBusNumber, DSPHeaders::BusBuffers ins, DSPHeaders::BusBuffers outs,
                   AUAudioFrameCount frameCount) noexcept {
    auto odd90 = odd90_.getImmediate();
    if (frameCount == 1) [[unlikely]] {
      auto delay = delay_.frameValue();
      auto depth = depth_.frameValue();
      auto feedback = (negativeFeedback_ ? -1.0 : 1.0) * feedback_.frameValue();
      auto [center, variance] = calcCenterVariance(delay, depth);
      auto [evenTap, oddTap] = odd90 ? calcDoubleTap(center, variance) : calcSingleTap(center, variance);
      writeSample(ins, outs, evenTap, oddTap, feedback, wetMix_.frameValue(), dryMix_.frameValue());
    } else [[likely]] {
      auto delay = delay_.finalValue();
      auto depth = depth_.finalValue();
      auto feedback = (negativeFeedback_ ? -1.0 : 1.0) * feedback_.finalValue();
      auto wetMix = wetMix_.finalValue();
      auto dryMix = dryMix_.finalValue();
      auto [center, variance] = calcCenterVariance(delay, depth);
      if (odd90) {
        while (frameCount-- >0) {
          auto [evenTap, oddTap] = calcDoubleTap(center, variance);
          writeSample(ins, outs, evenTap, oddTap, feedback, wetMix, dryMix);
        }
      } else {
        while (frameCount-- >0) {
          auto [evenTap, oddTap] = calcSingleTap(center, variance);
          writeSample(ins, outs, evenTap, oddTap, feedback, wetMix, dryMix);
        }
      }
    }
  }

  DSPHeaders::Parameters::Milliseconds delay_;
  DSPHeaders::Parameters::Percentage depth_;
  DSPHeaders::Parameters::Percentage feedback_;
  DSPHeaders::Parameters::Percentage dryMix_;
  DSPHeaders::Parameters::Percentage wetMix_;
  DSPHeaders::Parameters::Bool negativeFeedback_;
  DSPHeaders::Parameters::Bool odd90_;

  double samplesPerMillisecond_;
  double maxDelayMilliseconds_;

  std::vector<DelayLine> delayLines_;
  LFO lfo_;
  std::string name_;
  os_log_t log_;
};
