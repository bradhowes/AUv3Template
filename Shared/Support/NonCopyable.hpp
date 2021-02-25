// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

/**
 Simple class for prohibiting derived classes from being copied.
 */
class NonCopyable
{
protected:
    constexpr NonCopyable() = default;
    ~NonCopyable() = default;

private:
    NonCopyable(const NonCopyable&) = delete;
    NonCopyable& operator =(const NonCopyable&) = delete;
};
