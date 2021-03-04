// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <limits>

namespace Biquad {

/**
 Read-only filter coefficients.
 */
struct Coefficients {
    Coefficients()
    : a0{0}, a1{0}, a2{0}, b1{0}, b2{0}, c0{0}, d0{0} {}

    Coefficients(double _a0, double _a1, double _a2, double _b1, double _b2, double _c0, double _d0)
    : a0{_a0}, a1{_a1}, a2{_a2}, b1{_b1}, b2{_b2}, c0{_c0}, d0{_d0} {}

    Coefficients A0(double value) { return Coefficients(value, a1, a2, b1, b2, c0, d0); }
    Coefficients A1(double value) { return Coefficients(a0, value, a2, b1, b2, c0, d0); }
    Coefficients A2(double value) { return Coefficients(a0, a1, value, b1, b2, c0, d0); }
    Coefficients B1(double value) { return Coefficients(a0, a1, a2, value, b2, c0, d0); }
    Coefficients B2(double value) { return Coefficients(a0, a1, a2, b1, value, c0, d0); }
    Coefficients C0(double value) { return Coefficients(a0, a1, a2, b1, b2, value, d0); }
    Coefficients D0(double value) { return Coefficients(a0, a1, a2, b1, b2, c0, value); }

    const double a0;
    const double a1;
    const double a2;
    const double b1;
    const double b2;
    const double c0;
    const double d0;

    // 1-pole low-pass coefficients generator
    static Coefficients LPF1(double sampleRate, double cutoff) {
        double theta = 2.0 * M_PI * cutoff / sampleRate;
        double gamma = ::cos(theta) / (1.0 + ::sin(theta));
        return Coefficients()
        .A0((1.0 - gamma) / 2.0)
        .A1((1.0 - gamma) / 2.0)
        .A2(0.0)
        .B1(-gamma)
        .B2(0.0)
        .C0(1.0)
        .D0(0.0);
    }

    // 1-pole high-pass coefficients generator
    static Coefficients HPF1(double sampleRate, double cutoff) {
        double theta = 2.0 * M_PI * cutoff / sampleRate;
        double gamma = ::cos(theta) / (1.0 + ::sin(theta));
        return Coefficients()
        .A0((1.0 + gamma) / 2.0)
        .A1((1.0 + gamma) / -2.0)
        .A2(0.0)
        .B1(-gamma)
        .B2(0.0)
        .C0(1.0)
        .D0(0.0);
    }

    // 2-pole low-pass coefficients generator
    static Coefficients LPF2(double sampleRate, double cutoff, double resonance) {
        double theta = 2.0 * M_PI * cutoff / sampleRate;
        double d = 1.0 / resonance;
        double beta = 0.5 * (1 - d / 2.0 * ::sin(theta)) / (1 + d / 2.0 * ::sin(theta));
        double gamma = (0.5 + beta) * ::cos(theta);
        return Coefficients()
        .A0((0.5 + beta - gamma) / 2.0)
        .A1((0.5 + beta - gamma))
        .A2((0.5 + beta - gamma) / 2.0)
        .B1(-2.0 * gamma)
        .B2(2.0 / beta)
        .C0(1.0)
        .D0(0.0);
    }

    // 2-pole high-pass coefficients generator
    static Coefficients HPF2(double sampleRate, double cutoff, double resonance) {
        double theta = 2.0 * M_PI * cutoff / sampleRate;
        double d = 1.0 / resonance;
        double beta = 0.5 * (1 - d / 2.0 * ::sin(theta)) / (1 + d / 2.0 * ::sin(theta));
        double gamma = (0.5 + beta) * ::cos(theta);
        return Coefficients()
        .A0((0.5 + beta + gamma) / 2.0)
        .A1(-1.0 * (0.5 + beta + gamma))
        .A2((0.5 + beta + gamma) / 2.0)
        .B1(-2.0 * gamma)
        .B2(2.0 / beta)
        .C0(1.0)
        .D0(0.0);
    }

    // 1-pole all-pass coefficients generator
    static Coefficients APF1(double sampleRate, double cutoff) {
        double tangent = ::tan(M_PI * cutoff / sampleRate);
        double alpha = (tangent - 1.0) / (tangent + 1.0);
        return Coefficients()
        .A0(alpha)
        .A1(1.0)
        .A2(0.0)
        .B1(alpha)
        .B2(0.0)
        .C0(1.0)
        .D0(0.0);
    }

    // 2-pole all-pass coefficients generator
    static Coefficients APF2(double sampleRate, double cutoff, double resonance) {
        double BW = cutoff / resonance;
        double argTan = M_PI * BW / sampleRate;
        if (argTan >= 0.95 * M_PI / 2.0) argTan = 0.95 * M_PI / 2.0;
        double tangent = ::tan(argTan);
        double alpha = (tangent - 1.0) / (tangent + 1.0);
        double beta = -::cos(2.0 * M_PI * cutoff / sampleRate);
        return Coefficients()
        .A0(-alpha)
        .A1(beta * (1.0 - alpha))
        .A2(1.0)
        .B1(beta * (1.0 - alpha))
        .B2(-alpha)
        .C0(1.0)
        .D0(0.0);
    }
};

/**
 Mutable filter state.
 */
struct State {
    State() : x_z1{0}, x_z2{0}, y_z1{0}, y_z2{0} {}
    double x_z1;
    double x_z2;
    double y_z1;
    double y_z2;
};

namespace Transform {

struct Base {

    /// If value is too small to be represented in a `float`, force it to be zero.
    static double forceMinToZero(double value) {
        return ((value > 0.0 && value < std::numeric_limits<float>::min()) ||
                (value < 0.0 && value > -std::numeric_limits<float>::min())) ? 0.0 : value;
    }
};

// Transform for the 'direct' biquad structure
struct Direct : Base {
    static double transform(double input, State& state, Coefficients const& coefficients) {
        double output = coefficients.a0 * input + coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2 -
        coefficients.b1 * state.y_z1 - coefficients.b2 * state.y_z2;
        output = forceMinToZero(output);
        state.x_z2 = state.x_z1;
        state.x_z1 = input;
        state.y_z2 = state.y_z1;
        state.y_z1 = output;
        return output;
    }

    static double storageComponent(State const& state, Coefficients const& coefficients) {
        return coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2 - coefficients.b1 * state.y_z1 -
        coefficients.b2 * state.y_z2;
    }
};

// Transform for the 'canonical' biquad structure
struct Canonical : Base {
    static double transform(double input, State& state, Coefficients const& coefficients) {
        double theta = input - coefficients.b1 * state.x_z1 - coefficients.b2 * state.x_z2;
        double output = coefficients.a0 * theta + coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2;
        output = forceMinToZero(output);
        state.x_z2 = state.x_z1;
        state.x_z1 = theta;
        return output;
    }

    static double storageComponent(State const& state, Coefficients const& coefficients) { return 0.0; }
};

// Transform for the transposed 'direct' biquad structure
struct DirectTranspose : Base {
    static double transform(double input, State& state, Coefficients const& coefficients) {
        double theta = input + state.y_z1;
        double output = coefficients.a0 * theta + state.x_z1;
        output = forceMinToZero(output);
        state.y_z1 = state.y_z2 - coefficients.b1 * theta;
        state.y_z2 = -coefficients.b2 * theta;
        state.x_z1 = state.x_z2 + coefficients.a1 * theta;
        state.x_z2 = coefficients.a2 * theta;
        return output;
    }

    static double storageComponent(State const& state, Coefficients const& coefficients) { return 0.0; }
};

// Transform for the transposed 'canonical' biquad structure (preferred)
struct CanonicalTranspose : Base {
    static double transform(double input, State& state, Coefficients const& coefficients) {
        double output = coefficients.a0 * input + state.x_z1;
        output = forceMinToZero(output);
        state.x_z1 = coefficients.a1 * input - coefficients.b1 * output + state.x_z2;
        state.x_z2 = coefficients.a2 * input - coefficients.b2 * output;
        return output;
    }

    static double storageComponent(State const& state, Coefficients const& coefficients) { return state.x_z1; }
};

} // namespace Op

/**
 Generic biquad filter setup. Only knows how to reset its internal state and to transform (filter)
 values.
 */
template <typename Transformer>
class Filter {
public:

    /**
     Create a new filter using the given biquad coefficients.
     */
    Filter(Coefficients const& coefficients) : coefficients_{coefficients}, state_{} {}

    /**
     Use a new set of biquad coefficients.
     */
    void setCoefficients(Coefficients const& coefficients) {
        coefficients_ = coefficients;
        reset();
    }

    /**
     Reset internal state.
     */
    void reset() { state_ = State(); }

    /**
     Apply the filter to a given value.
     */
    double transform(double value) { return Transformer::transform(value, state_, coefficients_); }

    /**
     Obtain the `gain` value from the coefficients.
     */
    double gainValue() const { return coefficients_.a0; }

    /**
     Obtain a calculated state value.
     */
    double storageComponent() const { Transformer::storageComponent(state_, coefficients_); }

private:
    Coefficients coefficients_;
    State state_;
};

using Direct = Filter<Transform::Direct>;
using DirectTranspose = Filter<Transform::DirectTranspose>;
using Canonical = Filter<Transform::Canonical>;
using CanonicalTranspose = Filter<Transform::CanonicalTranspose>;

} // namespace Biquad
