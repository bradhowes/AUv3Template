// Copyright © 2022 Brad Howes. All rights reserved.

#import <CoreAudioKit/CoreAudioKit.h>

#import "C++/Kernel.hpp"
#import "KernelBridge.h"

@implementation KernelBridge {
  Kernel* kernel_;
  AUValue maxDelayMilliseconds_;
}

- (instancetype)init:(NSString*)appExtensionName maxDelayMilliseconds:(AUValue)maxDelayMilliseconds {
  if (self = [super init]) {
    self->kernel_ = new Kernel(std::string(appExtensionName.UTF8String));
    self->maxDelayMilliseconds_ = maxDelayMilliseconds;
  }
  return self;
}

- (void)setRenderingFormat:(NSInteger)busCount format:(AVAudioFormat*)inputFormat
         maxFramesToRender:(AUAudioFrameCount)maxFramesToRender {
  kernel_->setRenderingFormat(busCount, inputFormat, maxFramesToRender, maxDelayMilliseconds_);
}

- (void)deallocateRenderResources { kernel_->deallocateRenderResources(); }

- (AUInternalRenderBlock)internalRenderBlock:(nullable AUHostTransportStateBlock)tsb {
  __block auto dsp = kernel_;
  __block auto transportStateBlock = tsb;
  return ^AUAudioUnitStatus(AudioUnitRenderActionFlags* flags, const AudioTimeStamp* timestamp,
                            AUAudioFrameCount frameCount, NSInteger outputBusNumber, AudioBufferList* output,
                            const AURenderEvent* realtimeEventListHead, AURenderPullInputBlock pullInputBlock) {
    if (transportStateBlock) {
      AUHostTransportStateFlags flags;
      transportStateBlock(&flags, NULL, NULL, NULL);
      bool rendering = flags & AUHostTransportStateMoving;
      dsp->setRendering(rendering);
    }
    return dsp->processAndRender(timestamp, frameCount, outputBusNumber, output, realtimeEventListHead, pullInputBlock);
  };
}

- (void)setBypass:(BOOL)state { kernel_->setBypass(state); }

- (AUImplementorValueObserver)parameterValueObserverBlock {
  __block auto dsp = kernel_;
  return ^(AUParameter* parameter, AUValue value) { dsp->setParameterValuePending(parameter.address, value); };
}

- (AUImplementorValueProvider)parameterValueProviderBlock {
  __block auto dsp = kernel_;
  return ^AUValue(AUParameter* address) { return dsp->getParameterValuePending(address.address); };
}

@end
