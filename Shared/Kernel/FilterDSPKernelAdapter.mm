// Copyright © 2021 Brad Howes. All rights reserved.

#import <CoreAudioKit/CoreAudioKit.h>

#import "FilterDSPKernel.h"
#import "FilterDSPKernelAdapter.h"

@implementation FilterDSPKernelAdapter {
    FilterDSPKernel* kernel_;
}

- (instancetype)init:(NSString*)appExtensionName maxDelayMilliseconds:(float)maxDelay {
    if (self = [super init]) {
        self->kernel_ = new FilterDSPKernel(std::string(appExtensionName.UTF8String), maxDelay);
    }
    return self;
}

- (void)startProcessing:(AVAudioFormat*)inputFormat maxFramesToRender:(AUAudioFrameCount)maxFramesToRender {
    kernel_->startProcessing(inputFormat, maxFramesToRender);
}

- (void)stopProcessing {
    kernel_->stopProcessing();
}

- (void)set:(AUParameter *)parameter value:(AUValue)value { kernel_->setParameterValue(parameter.address, value); }

- (AUValue)get:(AUParameter *)parameter { return kernel_->getParameterValue(parameter.address); }

- (AUAudioUnitStatus) process:(AudioTimeStamp*)timestamp
                   frameCount:(UInt32)frameCount
                       output:(AudioBufferList*)output
                       events:(AURenderEvent*)realtimeEventListHead
               pullInputBlock:(AURenderPullInputBlock)pullInputBlock
{
    auto inputBus = 0;
    return kernel_->processAndRender(timestamp, frameCount, inputBus, output, realtimeEventListHead, pullInputBlock);
}

- (void)setBypass:(BOOL)state {
    kernel_->setBypass(state);
}

@end
