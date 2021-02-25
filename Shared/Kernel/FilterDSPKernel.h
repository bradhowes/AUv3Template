// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <AVFoundation/AVFoundation.h>

#import "DelayBuffer.h"
#import "FilterFramework/FilterFramework-Swift.h"
#import "KernelEventProcessor.h"
#import "LFO.h"

class FilterDSPKernel : public KernelEventProcessor<FilterDSPKernel> {
public:
    using super = KernelEventProcessor<FilterDSPKernel>;
    friend super;

    FilterDSPKernel(std::string const& name, float maxDelayMilliseconds)
    :
    super(os_log_create(name.c_str(), "FilterDSPKernel")),
    maxDelayMilliseconds_{maxDelayMilliseconds},
    delayLines_{}, lfo_()
    {}

    /**
     Update kernel and buffers to support the given format and channel count
     */
    void startProcessing(AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) {
        super::startProcessing(format, maxFramesToRender);
        initialize(format.channelCount, format.sampleRate);
    }

    void initialize(int channelCount, float sampleRate) {
        samplesPerMillisecond_ = sampleRate / 1000.0;
        delayInSamples_ = delay_ * samplesPerMillisecond_;
        lfo_.initialize(sampleRate, rate_);

        auto size = maxDelayMilliseconds_ * samplesPerMillisecond_ + 1;
        os_log_with_type(log_, OS_LOG_TYPE_INFO, "delayLine size: %f delayInSamples: %f", size, delayInSamples_);
        delayLines_.clear();
        for (int index = 0; index < channelCount; ++index)
            delayLines_.emplace_back(size);
    }

    void stopProcessing() { super::stopProcessing(); }

    void setParameterValue(AUParameterAddress address, AUValue value) {
        switch (address) {
            case FilterParameterAddressDepth:
                value = value / 100.0;
                if (value == depth_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "depth - %f", value);
                depth_ = value;
                break;
            case FilterParameterAddressRate:
                if (value == rate_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "rate - %f", value);
                rate_ = value;
                lfo_.setFrequency(rate_);
                break;
            case FilterParameterAddressDelay:
                if (value == delay_) return;
                delay_ = value;
                delayInSamples_ = samplesPerMillisecond_ * value;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "delay - %f  delayInSamples: %f", value, delayInSamples_);
                break;
            case FilterParameterAddressFeedback:
                value = value / 100.0;
                if (value == feedback_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "feedback - %f", value);
                feedback_ = value;
                break;
            case FilterParameterAddressDryMix:
                value = value / 100.0;
                if (value == dryMix_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "dryMix - %f", value);
                dryMix_ = value;
                break;
            case FilterParameterAddressWetMix:
                value = value / 100.0;
                if (value == wetMix_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "wetMix - %f", value);
                wetMix_ = value;
                break;
        }
    }

    AUValue getParameterValue(AUParameterAddress address) const {
        switch (address) {
            case FilterParameterAddressDepth: return depth_ * 100.0;
            case FilterParameterAddressRate: return rate_;
            case FilterParameterAddressDelay: return delay_;
            case FilterParameterAddressFeedback: return feedback_ * 100.0;
            case FilterParameterAddressDryMix: return dryMix_ * 100.0;
            case FilterParameterAddressWetMix: return wetMix_ * 100.0;
        }
        return 0.0;
    }

    float depth() const { return depth_; }
    float rate() const { return rate_; }
    float delay() const { return delay_; }
    float feedback() const { return feedback_; }
    float dryMix() const { return dryMix_; }
    float wetMix() const { return wetMix_; }

private:

    void doParameterEvent(AUParameterEvent const& event) { setParameterValue(event.parameterAddress, event.value); }

    void doRendering(std::vector<float const*> ins, std::vector<float*> outs, AUAudioFrameCount frameCount) {
//        os_log_with_type(log_, OS_LOG_TYPE_DEBUG, "delay: %f feedback: %f mix: %f delayInSamples: %f",
//                         delay_, feedback_, wetDryMix_, delayInSamples_);
        for (int frame = 0; frame < frameCount; ++frame) {
            auto lfoValue = lfo_.value();
            for (int channel = 0; channel < ins.size(); ++channel) {
                auto inputSample = ins[channel][frame];
                auto delayPos = lfoValue * depth_ * delayInSamples_ / 2.0 + delayInSamples_;
                auto delayedSample = delayLines_[channel].read(delayPos);
                delayLines_[channel].write(inputSample + feedback_ * delayedSample);
                outs[channel][frame] = wetMix_ * delayedSample + dryMix_ * inputSample;
            }
        }
    }

    void doMIDIEvent(AUMIDIEvent const& midiEvent) {}

    float maxDelayMilliseconds_;
    float samplesPerMillisecond_;
    float depth_;
    float rate_;
    float delay_;
    float delayInSamples_;
    float feedback_;
    float dryMix_;
    float wetMix_;

    std::vector<DelayBuffer<float>> delayLines_;
    LFO<float> lfo_;
};
