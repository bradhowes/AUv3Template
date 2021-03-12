// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#import "ValueChangeDetector.h"

@interface ValueChangeDetectorTests : XCTestCase
@end

static float accuracy = 0.00001;

@implementation ValueChangeDetectorTests

- (void)testInit {
    ValueChangeDetector<float> foo(123.4);
    XCTAssertEqualWithAccuracy(123.4, foo.value(), accuracy);
    XCTAssertEqualWithAccuracy(123.4, float(foo), accuracy);
    XCTAssertFalse(foo.wasChanged());
}

- (void)testChangeDetect {
    ValueChangeDetector<float> foo(123.4);
    XCTAssertFalse(foo.wasChanged());
    foo = 246.8;
    XCTAssertTrue(foo.wasChanged());
    XCTAssertFalse(foo.wasChanged());
}

- (void)testReset {
    ValueChangeDetector<float> foo(123.4);
    foo = 246.8;
    foo.reset();
    XCTAssertFalse(foo.wasChanged());
}

@end
