// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include "DSP.h"

/**
 Implementation of a low-frequency oscillator. Supports 3 waveform:

 - sinusoid
 - triangle
 - sawtooth

 Loosely based on code found in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
 */
template <typename T>
class LFO {
public:
    enum class Waveform { sinusoid, triangle, sawtooth };

    LFO() : sampleRate_{44100.0}, frequency_{1.0}, waveform_{Waveform::sinusoid} {
        reset();
    }

    LFO(T sampleRate, T frequency)
    : sampleRate_{sampleRate}, frequency_{frequency}, waveform_{Waveform::sinusoid} {
        reset();
    }

    LFO(T sampleRate, T frequency, Waveform waveform)
    : sampleRate_{sampleRate}, frequency_{frequency}, waveform_{waveform} {
        reset();
    }

    void initialize(T sampleRate, T frequency) {
        sampleRate_ = sampleRate;
        frequency_ = frequency;
        reset();
    }

    void setWaveform(Waveform waveform) {
        waveform_ = waveform;
    }

    void setFrequency(T frequency) {
        frequency_ = frequency;
        phaseIncrement_ = frequency_ / sampleRate_;
    }

    void reset() {
        phaseIncrement_ = frequency_ / sampleRate_;
        moduloCounter_ = phaseIncrement_ > 0 ? 0.0 : 1.0;
        quadPhaseCounter_ = 0.25;
    }

    /**
     Obtain the next value of the oscillator. Advances counters before returning.
     */
    T value() {
        T counter = moduloCounter_;
        moduloCounter_ = incrementModuloCounter(counter, phaseIncrement_);
        quadPhaseCounter_ = incrementModuloCounter(counter, 0.25);
        return waveformValue(counter);
    }

    /**
     Obtain a 90° advanced value. Note that unlike `value` above, this does not change state.
     */
    T quadPhaseValue() const { return waveformValue(quadPhaseCounter_); }

private:

    static T wrappedModuloCounter(T counter, T inc) {
        if (inc > 0 && counter >= 1.0) return counter - 1.0;
        if (inc < 0 && counter <= 0.0) return counter + 1.0;
        return counter;
    }

    static T incrementModuloCounter(T counter, T inc) {
        return wrappedModuloCounter(counter + inc, inc);
    }

    T waveformValue(T counter) const {
        switch (waveform_) {
            case Waveform::sinusoid: return DSP::parabolicSine(M_PI - counter * 2.0 * M_PI);
            case Waveform::sawtooth: return DSP::unipolarToBipolar(counter);
            case Waveform::triangle: return DSP::unipolarToBipolar(std::abs(DSP::unipolarToBipolar(counter)));
        }
    }

    T sampleRate_;
    T frequency_;
    Waveform waveform_;
    T moduloCounter_;
    T quadPhaseCounter_;
    T phaseIncrement_;
};

