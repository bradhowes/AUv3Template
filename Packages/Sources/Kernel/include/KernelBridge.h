// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Small Obj-C bridge between Swift and the C++ kernel classes. The `KernelBridge` Swift package
 contains the actual adoption of the `AUParameterHandler` and `AudioRenderer` protocols.
 */
@interface KernelBridge : NSObject

/**
 Create a new instance.

 @param appExtensionName the name of the app extension where this audio unit resides. Only used for logging.
 @param maxDelayMilliseconds the maximum delay value that is supported in the effect. This is used to
 determine how large of a delay buffer to allocate at start.
 */
- (nonnull id)init:(NSString*)appExtensionName maxDelayMilliseconds:(AUValue)maxDelayMilliseconds;

@end

// These are the functions that satisfy the AudioRenderer protocol
@interface KernelBridge (AudioRenderer)

/**
 Configure the kernel for new format and max frame in preparation to begin rendering

 @param busCount number of busses that the kernel must support
 @param inputFormat the current format of the input bus
 @param maxFramesToRender the max frames to expect in a render request
 */
- (void)setRenderingFormat:(NSInteger)busCount format:(AVAudioFormat*)inputFormat
         maxFramesToRender:(AUAudioFrameCount)maxFramesToRender;

/**
 Stop processing, releasing any resources used to support rendering.
 */
- (void)deallocateRenderResources;

/**
 Obtain a block to use for rendering with the kernel.

 @returns AUInternalRenderBlock instance
 */
- (AUInternalRenderBlock)internalRenderBlock:(nullable AUHostTransportStateBlock)tsb;

/**
 Set the bypass state.

 @param state new bypass value
 */
- (void)setBypass:(BOOL)state;

@end

// These are the functions that satisfy the AUParameterHandler protocol
@interface KernelBridge (AUParameterHandler)

- (AUImplementorValueObserver)parameterValueObserverBlock;

- (AUImplementorValueProvider)parameterValueProviderBlock;

@end

NS_ASSUME_NONNULL_END
