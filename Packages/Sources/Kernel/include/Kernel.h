// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Small Obj-C bridge between Swift and the C++ kernel classes. The `Bridge` package contains the actual adoption of the
 `AUParameterHandler` and `AudioRenderer` protocols.
 */
@interface KernelBridge : NSObject

- (nonnull id)init:(NSString*)appExtensionName maxDelayMilliseconds:(AUValue)maxDelayMilliseconds;

@end

// These are the functions that satisfy the AudioRenderer protocol
@interface KernelBridge (AudioRenderer)

/**
 Configure the kernel for new format and max frame in preparation to begin rendering

 @param busCount number of busses that the kernel must support
 @param inputFormat the current format of the input bus
 @param maxFramesToRender the max frames to expect in a render request
 @param maxDelayMilliseconds the max delay time in milliseconds
 */
- (void)setRenderingFormat:(NSInteger)busCount format:(AVAudioFormat*)inputFormat
         maxFramesToRender:(AUAudioFrameCount)maxFramesToRender;

/**
 Stop processing, releasing any resources used to support rendering.
 */
- (void)renderingStopped;

/**
 Obtain a block to use for rendering with the kernel.

 @returns AUInternalRenderBlock instance
 */
- (AUInternalRenderBlock)internalRenderBlock;

/**
 Set the bypass state.

 @param state new bypass value
 */
- (void)setBypass:(BOOL)state;

@end

// These are the functions that satisfy the AUParameterHandler protocol
@interface KernelBridge (AUParameterHandler)

- (void)set:(AUParameter *)parameter value:(AUValue)value;

- (AUValue)get:(AUParameter *)parameter;

@end

NS_ASSUME_NONNULL_END
