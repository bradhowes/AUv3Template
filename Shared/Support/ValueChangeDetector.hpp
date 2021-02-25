// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <atomic>
#import <AudioToolbox/AudioToolbox.h>

#import "NonCopyable.hpp"

/**
 Template class which provides a way to passively determine if a value changes. Useful in threaded environments where
 the value is changed in one thread, and detected and used in another. Uses a std::atomic counter to record when a
 change happened.
 */
template <typename T>
class ValueChangeDetector : NonCopyable {
public:
    using counter_type = std::atomic<int32_t>;

    /**
     Construct new parameter detector with an initial value.

     @param value the initial value of the parameter
     */
    explicit ValueChangeDetector(T value) : value_{value}, changeCounter_{0}
    {
        assert(changeCounter_.is_lock_free());
    }

    /**
     Reset the parameter to a known counter state.
     */
    void reset()
    {
        changeCounter_ = 0;
        lastUpdateCounter_ = 0;
    }

    /**
     Set a new value for the parameter.

     @param value the new value to use
     @returns reference to self
     */
    ValueChangeDetector<T>& operator =(T value)
    {
        value_ = value;
        std::atomic_fetch_add(&changeCounter_, 1);
        return *this;
    }

    /**
     Get the last value set for the parameter.

     @returns last value set
     */
    T value() const { return value_; }

    /**
     Get the last value set for the parameter.

     @returns last value set
     */
    operator T() const { return value_; }

    /**
     Determine if the parameter was changed since the last time it was checked. Note that this is a mutating operation:
     it will only return true once if there are no changes between calls.

     @returns true if so
     */
    bool wasChanged()
    {
        int32_t changeCounterValue = changeCounter_;
        if (lastUpdateCounter_ == changeCounterValue) return false;
        lastUpdateCounter_ = changeCounterValue;
        return true;
    }

private:
    T value_;
    counter_type changeCounter_; // NOTE: should only be manipulated in `operator =` method
    int32_t lastUpdateCounter_ = 0; // NOTE: should only be manipulated in `wasChanged` method
};
