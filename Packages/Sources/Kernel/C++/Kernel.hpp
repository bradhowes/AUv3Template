// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <string>
#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BoolParameter.hpp"
#import "DSPHeaders/BusBuffers.hpp"
#import "DSPHeaders/DelayBuffer.hpp"
#import "DSPHeaders/EventProcessor.hpp"
#import "DSPHeaders/MillisecondsParameter.hpp"
#import "DSPHeaders/LFO.hpp"
#import "DSPHeaders/PercentageParameter.hpp"

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
  Kernel(std::string name) noexcept : super(name) {}

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

  /**
   Process an AU parameter value change by updating the kernel.

   @param address the address of the parameter that changed
   @param value the new value for the parameter
   @param rampDuration number of frames to ramp to the new value
   */
  void setParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount rampDuration) noexcept;

  /**
   Obtain from the kernel the current value of an AU parameter.

   @param address the address of the parameter to return
   @returns current parameter value
   */
  AUValue getParameterValue(AUParameterAddress address) const noexcept;

private:
  using DelayLine = DSPHeaders::DelayBuffer<AUValue>;
  using LFO = DSPHeaders::LFO<AUValue>;

  void initialize(int channelCount, double sampleRate, double maxDelayMilliseconds) noexcept {
    samplesPerMillisecond_ = sampleRate / 1000.0;
    maxDelayMilliseconds_ = maxDelayMilliseconds;
    lfo_.setWaveform(LFOWaveform::triangle);
    lfo_.setSampleRate(sampleRate);

    auto size = maxDelayMilliseconds * samplesPerMillisecond_ + 1;
    os_log_with_type(log_, OS_LOG_TYPE_INFO, "delayLine size: %f", size);
    delayLines_.clear();
    for (auto index = 0; index < channelCount; ++index) {
      delayLines_.emplace_back(size);
    }
  }

  void setRate(AUValue rate, AUAudioFrameCount rampingDuration) noexcept {
    rate_.set(rate, rampingDuration);
    lfo_.setFrequency(rate, rampingDuration);
  }

  void setParameterFromEvent(const AUParameterEvent& event) noexcept {
    setParameterValue(event.parameterAddress, event.value, event.rampDurationSampleFrames);
  }

  void doRendering(NSInteger outputBusNumber, DSPHeaders::BusBuffers ins, DSPHeaders::BusBuffers outs,
                   AUAudioFrameCount frameCount) noexcept {

    auto rampCount = std::min(rampRemaining_, frameCount);
    if (rampCount > 0) {
      rampRemaining_ -= rampCount;
      for (; rampCount > 0; --rampCount, --frameCount) {
        renderFrames(1, ins, outs);
      }
    }

    // Non-ramping case
    if (frameCount > 0) {
      renderFrames(frameCount, ins, outs);
    }
  }

  void renderFrames(AUAudioFrameCount frameCount, DSPHeaders::BusBuffers ins, DSPHeaders::BusBuffers outs) noexcept {
    // Advance by frames in outer loop so we can ramp values when they change without having to save/restore state.
    for (int frame = 0; frame < frameCount; ++frame) {

      auto depth = depth_.frameValue();
      auto delay = delay_.frameValue();
      auto feedback = (negativeFeedback_ ? -1.0 : 1.0) * feedback_.frameValue();
      auto wetMix = wetMix_.frameValue();
      auto dryMix = dryMix_.frameValue();

      // This is the amount of delay that the LFO can oscillate over. A value of -1 in the LFO will result in 0.0 and a
      // value of +1 from the LFO will give `delaySpan`.
      auto delaySpan = depth - delay;

      // Calculate the delay signal for even channels (L)
      auto evenDelay = DSPHeaders::DSP::bipolarToUnipolar(lfo_.value()) * delaySpan + delay;

      // Optionally, odd channels (R) can be 90° out of phase with the even channels.
      auto oddDelay = odd90_ ? DSPHeaders::DSP::bipolarToUnipolar(lfo_.quadPhaseValue()) * delaySpan + delay : evenDelay;

      // Safe now to increment the LFO for the next frame.
      lfo_.increment();

      // Process the same frame in all of the channels
      for (int channel = 0; channel < ins.size(); ++channel) {
        auto inputSample = *ins[channel]++;
        auto delayedSample = delayLines_[channel].read((channel & 1) ? oddDelay : evenDelay);
        delayLines_[channel].write(inputSample + feedback * delayedSample);
        *outs[channel]++ = wetMix * delayedSample + dryMix * inputSample;
      }
    }
  }

  void doMIDIEvent(const AUMIDIEvent& midiEvent) noexcept {}

  DSPHeaders::Parameters::RampingParameter<AUValue> rate_;
  DSPHeaders::Parameters::MillisecondsParameter<AUValue> depth_;
  DSPHeaders::Parameters::MillisecondsParameter<AUValue> delay_;
  DSPHeaders::Parameters::PercentageParameter<AUValue> feedback_;
  DSPHeaders::Parameters::PercentageParameter<AUValue> dryMix_;
  DSPHeaders::Parameters::PercentageParameter<AUValue> wetMix_;
  DSPHeaders::Parameters::BoolParameter negativeFeedback_;
  DSPHeaders::Parameters::BoolParameter odd90_;

  double samplesPerMillisecond_;
  double maxDelayMilliseconds_;

  std::vector<DelayLine> delayLines_;
  LFO lfo_;
  AUAudioFrameCount rampRemaining_;
};
