// Copyright © 2021 Brad Howes. All rights reserved.

#import <CoreAudioKit/CoreAudioKit.h>

#import "__NAME__Kernel.h"
#import "__NAME__KernelAdapter.h"

@implementation __NAME__KernelAdapter {
  __NAME__Kernel* kernel_;
  AUAudioFrameCount _maxFramesToRender;
}

- (instancetype)init:(NSString*)appExtensionName {
  if (self = [super init]) {
    self->kernel_ = new __NAME__Kernel(std::string(appExtensionName.UTF8String),
                                       AudioUnitParameters.maxDelayMilliseconds);
  }
  return self;
}

- (void)startProcessing:(AVAudioFormat*)inputFormat maxFramesToRender:(AUAudioFrameCount)maxFramesToRender {
  _maxFramesToRender = maxFramesToRender;
  kernel_->startProcessing(inputFormat, maxFramesToRender);
}

- (void)stopProcessing {
  kernel_->stopProcessing();
}

- (void)set:(AUParameter *)parameter value:(AUValue)value { kernel_->setParameterValue(parameter.address, value); }

- (AUValue)get:(AUParameter *)parameter { return kernel_->getParameterValue(parameter.address); }

- (void)setBypass:(BOOL)state {
  kernel_->setBypass(state);
}

- (AUInternalRenderBlock)internalRenderBlock {

  // Some code I've seen uses `__block` attributes for values copied to the block/stack. I don't see the need for them
  // when the values are read-only.
  //
  auto& kernel{*kernel_};
  AUAudioFrameCount maxFramesToRender = _maxFramesToRender;

  return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                            const AudioTimeStamp       *timestamp,
                            AUAudioFrameCount           frameCount,
                            NSInteger                   outputBusNumber,
                            AudioBufferList            *outputData,
                            const AURenderEvent        *realtimeEventListHead,
                            AURenderPullInputBlock      pullInputBlock) {

    if (outputBusNumber != 0) return kAudioUnitErr_InvalidPropertyValue;
    if (frameCount > maxFramesToRender) return kAudioUnitErr_TooManyFramesToProcess;
    if (pullInputBlock == nullptr) return kAudioUnitErr_NoConnection;

    auto inputBus = 0;
    return kernel.processAndRender(timestamp, frameCount, inputBus, outputData, realtimeEventListHead, pullInputBlock);
  };
}

@end
