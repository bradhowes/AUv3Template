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

  kernel->setParameterValue(ParameterAddressDepth, 10.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressDepth), 10.0, 0.001);

  kernel->setParameterValue(ParameterAddressDelay, 20.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressDelay), 20.0, 0.001);

  kernel->setParameterValue(ParameterAddressRate, 30.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressRate), 30.0, 0.001);

  kernel->setParameterValue(ParameterAddressFeedback, 40.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressFeedback), 40.0, 0.001);

  kernel->setParameterValue(ParameterAddressDry, 50.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressDry), 50.0, 0.001);

  kernel->setParameterValue(ParameterAddressWet, 60.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressWet), 60.0, 0.001);

  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressNegativeFeedback), 0.0, 0.001);
  kernel->setParameterValue(ParameterAddressNegativeFeedback, 1.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressNegativeFeedback), 1.0, 0.001);

  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressOdd90), 0.0, 0.001);
  kernel->setParameterValue(ParameterAddressOdd90, 1.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressOdd90), 1.0, 0.001);
}

@end
