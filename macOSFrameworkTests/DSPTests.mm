// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSP.h"

@interface DSPTests : XCTestCase

@end

@implementation DSPTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testClamp {
    XCTAssertEqual(DSP::clamp(0.0, 1.0, 2.0), 1.0);
    XCTAssertEqual(DSP::clamp(1.3, 1.0, 2.0), 1.3);
    XCTAssertEqual(DSP::clamp(2.1, 1.0, 2.0), 2.0);

    XCTAssertEqual(DSP::clamp( 0.0, -1.0, 1.0),  0.0);
    XCTAssertEqual(DSP::clamp(-1.3, -1.0, 1.0), -1.0);
    XCTAssertEqual(DSP::clamp( 2.1, -1.0, 1.0),  1.0);
}

- (void)testUnipolarModulation {
    XCTAssertEqual(DSP::unipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::unipolarModulation(0.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::unipolarModulation(0.5, 10.0, 20.0), 15.0);
    XCTAssertEqual(DSP::unipolarModulation(1.0, 10.0, 20.0), 20.0);
    XCTAssertEqual(DSP::unipolarModulation(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
    XCTAssertEqual(DSP::bipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::bipolarModulation(-1.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::bipolarModulation(0.0, 10.0, 20.0), 15.0);
    XCTAssertEqual(DSP::bipolarModulation(1.0, 10.0, 20.0), 20.0);
}

- (void)testUnipolarToBipolar {
    XCTAssertEqual(DSP::unipolarToBipolar(0.0), -1.0);
    XCTAssertEqual(DSP::unipolarToBipolar(0.5), 0.0);
    XCTAssertEqual(DSP::unipolarToBipolar(1.0), 1.0);
}

- (void)testBipolarToUnipolar {
    XCTAssertEqual(DSP::bipolarToUnipolar(-1.0), 0.0);
    XCTAssertEqual(DSP::bipolarToUnipolar(0.0), 0.5);
    XCTAssertEqual(DSP::bipolarToUnipolar(1.0), 1.0);
}

- (void)testZZZ {
    for (float modulator = -1.0; modulator <= 1.0; modulator += 0.1) {
        auto a = DSP::unipolarModulation<float>(DSP::bipolarToUnipolar<float>(modulator), 0.0, 10.0);
        auto b = DSP::bipolarModulation<float>(modulator, 0.0, 10.0);
        NSLog(@"%f %f", a, b);
    }
}

@end
