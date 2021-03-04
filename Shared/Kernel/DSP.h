// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <cmath>

namespace DSP {

template <typename T> T clamp(T value, T minValue, T maxValue) {
    return std::max(std::min(value, maxValue), minValue);
}

template <typename T> T unipolarModulation(T modulator, T minValue, T maxValue) {
    return clamp<T>(modulator, 0.0, 1.0) * (maxValue - minValue) + minValue;
}

template <typename T> T bipolarModulation(T modulator, T minValue, T maxValue) {
    auto half = (maxValue - minValue) / 2.0;
    return clamp<T>(modulator, -1.0, 1.0) * half + half + minValue;
}

template <typename T> T unipolarToBipolar(T modulator) { return 2.0 * modulator - 1.0; }

template <typename T> T bipolarToUnipolar(T modulator) { return 0.5 * modulator + 0.5; }

// Derived from code in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
template <typename T> T parabolicSine(T angle) {
    const T B = 4.0 / M_PI;
    const T C = -4.0 / (M_PI * M_PI);
    const T P = 0.225;
    T y = B * angle + C * angle * std::abs(angle);
    return P * (y * std::abs(y) - y) + y;
}

}
