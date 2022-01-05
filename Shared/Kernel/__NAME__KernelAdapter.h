// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <AudioToolbox/AudioToolbox.h>

/**
 Protocol that handles AUParameter get and set operations.
 */
@protocol AUParameterHandler

/**
 Set an AUParameter to a new value
 */
- (void)set:(nonnull AUParameter *)parameter value:(AUValue)value;

/**
 Get the current value of an AUParameter
 */
- (AUValue)get:(nonnull AUParameter *)parameter;

@end

/**
 Small Obj-C wrapper around the FilterDSPKernel C++ class. Handles AUParameter get/set requests by forwarding them to
 the kernel.
 */
@interface __NAME__KernelAdapter : NSObject <AUParameterHandler>

- (nonnull id)init:(nonnull NSString*)appExtensionName;

/**
 Configure the kernel for new format and max frame in preparation to begin rendering

 @param inputFormat the current format of the input bus
 @param maxFramesToRender the max frames to expect in a render request
 */
- (void)startProcessing:(nonnull AVAudioFormat*)inputFormat maxFramesToRender:(AUAudioFrameCount)maxFramesToRender;

/**
 Stop processing, releasing any resources used to support rendering.
 */
- (void)stopProcessing;

/**
 Obtain an `internalRenderBlock` to use for the AudioUnit. This is pretty much a straight connection into the kernel
 with a splash of input value checking.
 */
- (nonnull AUInternalRenderBlock)internalRenderBlock;

/**
 Set the bypass state.

 @param state new bypass value
 */
- (void)setBypass:(BOOL)state;

@end
