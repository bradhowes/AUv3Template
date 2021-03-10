// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <string>
#import <AVFoundation/AVFoundation.h>

#import "DelayBuffer.h"
#import "__NAME__Framework/__NAME__Framework-Swift.h"
#import "KernelEventProcessor.h"
#import "LFO.h"

class FilterDSPKernel : public KernelEventProcessor<FilterDSPKernel> {
public:
    using super = KernelEventProcessor<FilterDSPKernel>;
    friend super;

    FilterDSPKernel(const std::string& name, double maxDelayMilliseconds)
    : super(os_log_create(name.c_str(), "FilterDSPKernel")), maxDelayMilliseconds_{maxDelayMilliseconds},
    delayLines_{}, lfo_()
    {
        lfo_.setWaveform(LFOWaveform::triangle);
    }

    /**
     Update kernel and buffers to support the given format and channel count
     */
    void startProcessing(AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) {
        super::startProcessing(format, maxFramesToRender);
        initialize(format.channelCount, format.sampleRate);
    }

    void initialize(int channelCount, double sampleRate) {
        samplesPerMillisecond_ = sampleRate / 1000.0;
        delayInSamples_ = delay_ * samplesPerMillisecond_;
        lfo_.initialize(sampleRate, rate_);

        auto size = maxDelayMilliseconds_ * samplesPerMillisecond_ + 1;
        os_log_with_type(log_, OS_LOG_TYPE_INFO, "delayLine size: %f delayInSamples: %f", size, delayInSamples_);
        delayLines_.clear();
        for (int index = 0; index < channelCount; ++index) {
            delayLines_.emplace_back(size);
        }
    }

    void stopProcessing() { super::stopProcessing(); }

    void setParameterValue(AUParameterAddress address, AUValue value) {
        double tmp;
        switch (address) {
            case FilterParameterAddressDepth:
                tmp = value / 200.0; // !!!
                if (tmp == depth_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "depth - %f", tmp);
                depth_ = tmp;
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
                tmp = value / 100.0;
                if (tmp == feedback_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "feedback - %f", tmp);
                feedback_ = tmp;
                break;
            case FilterParameterAddressDryMix:
                tmp = value / 100.0;
                if (tmp == dryMix_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "dryMix - %f", tmp);
                dryMix_ = tmp;
                break;
            case FilterParameterAddressWetMix:
                tmp = value / 100.0;
                if (tmp == wetMix_) return;
                os_log_with_type(log_, OS_LOG_TYPE_INFO, "wetMix - %f", tmp);
                wetMix_ = tmp;
                break;
        }
    }

    AUValue getParameterValue(AUParameterAddress address) const {
        switch (address) {
            case FilterParameterAddressDepth: return depth_ * 200.0; // !!!
            case FilterParameterAddressRate: return rate_;
            case FilterParameterAddressDelay: return delay_;
            case FilterParameterAddressFeedback: return feedback_ * 100.0;
            case FilterParameterAddressDryMix: return dryMix_ * 100.0;
            case FilterParameterAddressWetMix: return wetMix_ * 100.0;
        }
        return 0.0;
    }

private:

    void doParameterEvent(const AUParameterEvent& event) { setParameterValue(event.parameterAddress, event.value); }

    void doRendering(std::vector<AUValue const*> ins, std::vector<AUValue*> outs, AUAudioFrameCount frameCount) {
        for (int frame = 0; frame < frameCount; ++frame) {
            auto lfoValue = lfo_.valueAndIncrement();
            for (int channel = 0; channel < ins.size(); ++channel) {
                AUValue inputSample = ins[channel][frame];
                double delayPos = lfoValue * depth_ * delayInSamples_ + delayInSamples_;
                AUValue delayedSample = delayLines_[channel].read(delayPos);
                delayLines_[channel].write(inputSample + feedback_ * delayedSample);
                outs[channel][frame] = wetMix_ * delayedSample + dryMix_ * inputSample;
            }
        }
    }

    void doMIDIEvent(const AUMIDIEvent& midiEvent) {}

    double depth_; // NOTE: this ranges from 0.0 - 0.5 to absorb a / 2 operation in the delayPos calculation
    double rate_;
    double delay_;
    double feedback_;
    double dryMix_;
    double wetMix_;

    double maxDelayMilliseconds_;
    double samplesPerMillisecond_;
    double delayInSamples_;
    std::vector<DelayBuffer<AUValue>> delayLines_;
    LFO<double> lfo_;
};
