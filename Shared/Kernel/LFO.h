// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include "DSP.h"

template <typename T>
class LFO {
public:
    LFO() : sampleRate_{44100.0}, frequency_{1.0} {
        reset();
    }

    LFO(float sampleRate, float frequency) : sampleRate_{sampleRate}, frequency_{frequency} {
        reset();
    }

    void initialize(float sampleRate, float frequency) {
        sampleRate_ = sampleRate;
        frequency_ = frequency;
        reset();
    }

    void setFrequency(float frequency) {
        frequency_ = frequency;
        phaseIncrement_ = frequency_ / sampleRate_;
    }

    void reset() {
        phaseIncrement_ = frequency_ / sampleRate_;
        moduloCounter_ = 0.0;
    }

    T value() {
        checkAndWrapModulo();
        float angle = moduloCounter_ * 2.0 * M_PI - M_PI;
        float output = DSP::parabolicSine(-angle);
        moduloCounter_ += phaseIncrement_;
        return output;
    }

private:

    void checkAndWrapModulo() {
        while (phaseIncrement_ > 0 && moduloCounter_ >= 1.0) {
            moduloCounter_ -= 1.0;
        }
        while (phaseIncrement_ < 0 && moduloCounter_ <= 0.0) {
            moduloCounter_ += 1.0;
        }
    }

    T sampleRate_;
    T frequency_;
    T moduloCounter_;
    T phaseIncrement_;
};

