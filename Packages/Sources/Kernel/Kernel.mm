#import "C++/Kernel.hpp"

// This must be done in a source file -- include files cannot see the Swift bridging file.

@import ParameterAddress;

void Kernel::setRampedParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) noexcept {
  os_log_with_type(log_, OS_LOG_TYPE_DEBUG, "setParameterValue - %llul %f %d", address, value, duration);
  // Setting ramped values are safe -- they come from the event loop and are interleaved with rendering
  switch (address) {
    case ParameterAddressDepth: depth_.set(value, duration); break;
    case ParameterAddressRate: lfo_.setFrequency(value, duration); break;
    case ParameterAddressDelay: delay_.set(value, duration); break;
    case ParameterAddressFeedback: feedback_.set(value, duration); break;
    case ParameterAddressDry: dryMix_.set(value, duration); break;
    case ParameterAddressWet: wetMix_.set(value, duration); break;
    case ParameterAddressNegativeFeedback: negativeFeedback_.set(value, duration); break;
    case ParameterAddressOdd90: odd90_.set(value, duration); break;
  }
}

void Kernel::setParameterValuePending(AUParameterAddress address, AUValue value) noexcept {
  switch (address) {
    case ParameterAddressDepth: depth_.setPending(value); break;
    case ParameterAddressRate: lfo_.setFrequencyPending(value); break;
    case ParameterAddressDelay: delay_.setPending(value); break;
    case ParameterAddressFeedback: feedback_.setPending(value); break;
    case ParameterAddressDry: dryMix_.setPending(value); break;
    case ParameterAddressWet: wetMix_.setPending(value); break;
    case ParameterAddressNegativeFeedback: negativeFeedback_.setPending(value); break;
    case ParameterAddressOdd90: odd90_.setPending(value); break;
  }
}

AUValue Kernel::getParameterValuePending(AUParameterAddress address) const noexcept {
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
