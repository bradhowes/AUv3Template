// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <Accelerate/Accelerate.h>
#include <cmath>
#include <vector>

template <typename T>
class DelayBuffer {
public:
    DelayBuffer(float sizeInSamples)
    :
    wrapMask_{smallestPowerOf2For(sizeInSamples) - 1},
    buffer_(wrapMask_ + 1, 0.0),
    writePos_{0}
    {
        clear();
    }

    void clear() {
        std::fill(buffer_.begin(), buffer_.end(), 0.0);
    }

    void setSizeInSamples(float sizeInSamples) {
        wrapMask_ = smallestPowerOf2For(sizeInSamples) - 1;
        buffer_.resize(wrapMask_ + 1);
        writePos_ = 0;
        clear();
    }

    void write(T value) {
        buffer_[writePos_] = value;
        writePos_ = (writePos_ + 1) & wrapMask_;
    }

    size_t size() const { return buffer_.size(); }

    T readFromOffset(int offset) const {
        return buffer_[(writePos_ - offset) & wrapMask_]; }

    T read(float delay) const {
        T y1 = readFromOffset(int(delay));
        T y2 = readFromOffset(int(delay + 1));
        auto partial = delay - int(delay);
        assert(partial >= 0.0 && partial < 1.0);
        return y2 * partial + (1.0 - partial) * y1;
    }

private:

    static size_t smallestPowerOf2For(float value) {
        return size_t(::pow(2.0, ::ceil(::log2(::fmaxf(value, 1.0)))));
    }

    size_t wrapMask_;
    std::vector<T> buffer_;
    size_t writePos_;
};

