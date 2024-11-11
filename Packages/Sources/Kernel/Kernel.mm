#import "C++/Kernel.hpp"

// This must be done in a source file -- include files cannot see the Swift bridging file.

@import ParameterAddress;

bool Kernel::doSetImmediateParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) noexcept {
  switch (address) {
    case ParameterAddressDepth: depth_.setImmediate(value, duration); return true;
    case ParameterAddressRate: lfo_.setFrequency(value, duration); return true;
    case ParameterAddressDelay: delay_.setImmediate(value, duration); return true;
    case ParameterAddressFeedback: feedback_.setImmediate(value, duration); return true;
    case ParameterAddressDry: dryMix_.setImmediate(value, duration); return true;
    case ParameterAddressWet: wetMix_.setImmediate(value, duration); return true;
    case ParameterAddressNegativeFeedback: negativeFeedback_.setImmediate(value, duration); return true;
    case ParameterAddressOdd90: odd90_.setImmediate(value, duration); return true;
  }
  return false;
}

bool Kernel::doSetPendingParameterValue(AUParameterAddress address, AUValue value) noexcept {
  switch (address) {
    case ParameterAddressDepth: depth_.setPending(value); return true;
    case ParameterAddressRate: lfo_.setFrequencyPending(value); return true;
    case ParameterAddressDelay: delay_.setPending(value); return true;
    case ParameterAddressFeedback: feedback_.setPending(value); return true;
    case ParameterAddressDry: dryMix_.setPending(value); return true;
    case ParameterAddressWet: wetMix_.setPending(value); return true;
    case ParameterAddressNegativeFeedback: negativeFeedback_.setPending(value); return true;
    case ParameterAddressOdd90: odd90_.setPending(value); return true;
  }
}

AUValue Kernel::doGetImmediateParameterValue(AUParameterAddress address) const noexcept {
  switch (address) {
    case ParameterAddressDepth: return depth_.getImmediate();
    case ParameterAddressRate: return lfo_.frequency();
    case ParameterAddressDelay: return delay_.getImmediate();
    case ParameterAddressFeedback: return feedback_.getImmediate();
    case ParameterAddressDry: return dryMix_.getImmediate();
    case ParameterAddressWet: return wetMix_.getImmediate();
    case ParameterAddressNegativeFeedback: return negativeFeedback_.getImmediate();
    case ParameterAddressOdd90: return odd90_.getImmediate();
  }
  return 0.0;
}

AUValue Kernel::doGetPendingParameterValue(AUParameterAddress address) const noexcept {
  switch (address) {
    case ParameterAddressDepth: return depth_.getPending();
    case ParameterAddressRate: return lfo_.frequencyPending();
    case ParameterAddressDelay: return delay_.getPending();
    case ParameterAddressFeedback: return feedback_.getPending();
    case ParameterAddressDry: return dryMix_.getPending();
    case ParameterAddressWet: return wetMix_.getPending();
    case ParameterAddressNegativeFeedback: return negativeFeedback_.getPending();
    case ParameterAddressOdd90: return odd90_.getPending();
  }
  return 0.0;
}
