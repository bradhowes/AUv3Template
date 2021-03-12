// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#import "RampingValueChangeDetector.h"

@interface RampingValueChangeDetectorTests : XCTestCase
@end

static float accuracy = 0.00001;

@implementation RampingValueChangeDetectorTests

- (void)testInit {
    RampingValueChangeDetector<float, int> foo(123.4);
    XCTAssertEqualWithAccuracy(123.4, foo.value(), accuracy);
    XCTAssertEqualWithAccuracy(123.4, float(foo), accuracy);
    XCTAssertFalse(foo.wasChanged());
}

- (void)testChangeDetect {
    RampingValueChangeDetector<float, int> foo(123.4);
    XCTAssertFalse(foo.wasChanged());
    foo = 246.8;
    XCTAssertTrue(foo.wasChanged());
    XCTAssertFalse(foo.wasChanged());
}

- (void)testReset {
    RampingValueChangeDetector<float, int> foo(123.4);
    foo = 246.8;
    foo.startRamping(2);
    XCTAssertTrue(foo.isRamping());
    foo.reset();
    XCTAssertFalse(foo.isRamping());
    XCTAssertEqualWithAccuracy(246.8, foo.value(), accuracy);
}

- (void)testRamping {
    RampingValueChangeDetector<float, int> foo(10.0);
    foo = 20.0;
    foo.startRamping(2);
    XCTAssertTrue(foo.isRamping());
    XCTAssertEqualWithAccuracy(10.0, foo.getAndStep(), accuracy);
    XCTAssertEqualWithAccuracy(20.0, foo.value(), accuracy);
    XCTAssertTrue(foo.isRamping());
    XCTAssertEqualWithAccuracy(15.0, foo.getAndStep(), accuracy);
    XCTAssertFalse(foo.isRamping());
    XCTAssertEqualWithAccuracy(20.0, foo.getAndStep(), accuracy);
    XCTAssertEqualWithAccuracy(20.0, foo.getAndStep(), accuracy);
}

- (void)testStepBy {
    RampingValueChangeDetector<float, int> foo(100.0);
    foo = 200.0;
    foo.startRamping(10);
    XCTAssertTrue(foo.isRamping());
    XCTAssertEqualWithAccuracy(100.0, foo.ramped(), accuracy);
    foo.stepBy(1);
    XCTAssertTrue(foo.isRamping());
    XCTAssertEqualWithAccuracy(110.0, foo.ramped(), accuracy);
    foo.stepBy(2);
    XCTAssertEqualWithAccuracy(130.0, foo.ramped(), accuracy);
    foo.stepBy(2);
    XCTAssertEqualWithAccuracy(150.0, foo.ramped(), accuracy);
    foo.stepBy(0);
    XCTAssertEqualWithAccuracy(150.0, foo.ramped(), accuracy);
    foo.stepBy(-1);
    XCTAssertEqualWithAccuracy(150.0, foo.ramped(), accuracy);
    foo.stepBy(99);
    XCTAssertEqualWithAccuracy(200.0, foo.ramped(), accuracy);
    XCTAssertFalse(foo.isRamping());
}

@end
