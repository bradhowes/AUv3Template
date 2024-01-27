// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "../../Sources/Kernel/C++/Kernel.hpp"

@import ParameterAddress;

@interface KernelTests : XCTestCase

@end

@implementation KernelTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testKernelParams {
  Kernel* kernel = new Kernel("blah");
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  kernel->setRenderingFormat(1, format, 100, 20.0);

  kernel->setParameterValuePending(ParameterAddressDepth, 10.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressDepth), 10.0, 0.001);

  kernel->setParameterValuePending(ParameterAddressDelay, 20.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressDelay), 20.0, 0.001);

  kernel->setParameterValuePending(ParameterAddressRate, 30.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressRate), 30.0, 0.001);

  kernel->setParameterValuePending(ParameterAddressFeedback, 40.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressFeedback), 40.0, 0.001);

  kernel->setParameterValuePending(ParameterAddressDry, 50.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressDry), 50.0, 0.001);

  kernel->setParameterValuePending(ParameterAddressWet, 60.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressWet), 60.0, 0.001);

  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressNegativeFeedback), 0.0, 0.001);
  kernel->setParameterValuePending(ParameterAddressNegativeFeedback, 1.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressNegativeFeedback), 1.0, 0.001);

  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressOdd90), 0.0, 0.001);
  kernel->setParameterValuePending(ParameterAddressOdd90, 1.0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValuePending(ParameterAddressOdd90), 1.0, 0.001);
}

@end
