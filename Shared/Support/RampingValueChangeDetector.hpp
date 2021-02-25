// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <atomic>
#import <AudioToolbox/AudioToolbox.h>

#import "ValueChangeDetector.hpp"

/**
 Adaptation of a ValueChangeDetector that will provide ramped values when set to a new value.
 */
template <typename T, typename C>
class RampingValueChangeDetector : public ValueChangeDetector<T> {
public:
    using Super = ValueChangeDetector<T>;

    /**
     Construct new parameter ramp with an initial value.

     @param value the initial value of the parameter
     */
    explicit RampingValueChangeDetector(T value) : Super(value), offset_{value} {}

    /**
     Reset the parameter to a known counter state.
     */
    void reset() {
        samplesRemaining_ = 0;
        offset_ = Super::value();
        Super::reset();
    }

    /**
     Set a new value for the parameter.

     @param value the new value to use
     @returns reference to self
     */
    RampingValueChangeDetector<T, C>& operator =(T value)
    {
        Super::operator =(value);
        return *this;
    }

    /**
     Begin ramping values from current value to pending one over the given duration.

     NOTE: this should be run only in the reader thread

     @param duration how many samples to transition to new value
     @returns true if ramping to new value
     */
    bool startRamping(C duration)
    {
        if (this->wasChanged()) initRamp(duration);
        return samplesRemaining_ != 0;
    }

    bool isRamping() const { return samplesRemaining_ != 0; }

    /**
     Move along the ramp.
     */
    void step()
    {
        if (samplesRemaining_ != 0) --samplesRemaining_;
    }

    /**
     Obtain the current ramped value and move along the ramp.

     @return current ramped value
     */
    T getAndStep()
    {
        if (samplesRemaining_ == 0) return this->value();
        T value(ramped());
        --samplesRemaining_;
        return value;
    }

    /**
     Move along the ramp multiple times.

     @param frameCount number of times to move
     */
    void stepBy(C frameCount)
    {
        if (frameCount >= samplesRemaining_) {
            samplesRemaining_ = 0;
        }
        else if (frameCount > 0) {
            samplesRemaining_ -= frameCount;
        }
    }

    /**
     Get the current 'ramped' value. If no more samples remaining, then this will return the last set value.
     */
    T ramped() const { return slope_ * T(samplesRemaining_) + offset_; }

private:

    void initRamp(C duration) {
        if (duration > 0) slope_ = (ramped() - this->value()) / T(duration);
        samplesRemaining_ = duration;
        offset_ = this->value();
    }

    T slope_ = 0.0;
    T offset_;
    C samplesRemaining_ = 0;
};
