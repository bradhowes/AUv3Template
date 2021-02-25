// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "LFO.h"

@interface LFOTests : XCTestCase

@end

@implementation LFOTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSamples {
    LFO<float> osc(4.0, 1.0);
    XCTAssertEqualWithAccuracy(osc.value(),  0.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(),  1.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(),  0.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(), -1.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(),  0.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(),  1.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(),  0.0, 0.0001);
    XCTAssertEqualWithAccuracy(osc.value(), -1.0, 0.0001);
}

- (void)testAccuracy {
    LFO<double> osc(360.0, 1.0);
    osc.initialize(360.0, 1.0);
    for (int index = 0; index < 360.0; ++index) {
        auto theta = 2 * M_PI * index / 360.0;
        auto real = ::sin(theta);
        XCTAssertEqualWithAccuracy(osc.value(), real, 0.0011);
    }
}

@end
