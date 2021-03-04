// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "LFO.h"

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

@interface LFOTests : XCTestCase
@property float epsilon;
@end

@implementation LFOTests

- (void)setUp {
    _epsilon = 0.0001;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSinusoidSamples {
    LFO<float> osc(4.0, 1.0, LFO<float>::Waveform::sinusoid);
    SamplesEqual(osc.value(),  0.0);
    SamplesEqual(osc.value(),  1.0);
    SamplesEqual(osc.value(),  0.0);
    SamplesEqual(osc.value(), -1.0);
    SamplesEqual(osc.value(),  0.0);
    SamplesEqual(osc.value(),  1.0);
    SamplesEqual(osc.value(),  0.0);
    SamplesEqual(osc.value(), -1.0);
}

- (void)testSawtoothSamples {
    LFO<float> osc(8.0, 1.0, LFO<float>::Waveform::sawtooth);
    SamplesEqual(osc.value(), -1.00);
    SamplesEqual(osc.value(), -0.75);
    SamplesEqual(osc.value(), -0.50);
    SamplesEqual(osc.value(), -0.25);
    SamplesEqual(osc.value(),  0.00);
    SamplesEqual(osc.value(),  0.25);
    SamplesEqual(osc.value(),  0.50);
    SamplesEqual(osc.value(),  0.75);
    SamplesEqual(osc.value(), -1.00);
}

- (void)testTriangleSamples {
    LFO<float> osc(8.0, 1.0, LFO<float>::Waveform::triangle);
    SamplesEqual(osc.value(),  1.0);
    SamplesEqual(osc.value(),  0.5);
    SamplesEqual(osc.value(),  0.0);
    SamplesEqual(osc.value(), -0.5);
    SamplesEqual(osc.value(), -1.0);
    SamplesEqual(osc.value(), -0.5);
    SamplesEqual(osc.value(),  0.0);
    SamplesEqual(osc.value(),  0.5);
    SamplesEqual(osc.value(),  1.0);
}

- (void)testQuadPhaseSamples {
    LFO<float> osc(8.0, 1.0, LFO<float>::Waveform::sawtooth);
    SamplesEqual(osc.value(), -1.00);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
    SamplesEqual(osc.value(), -0.75);
    SamplesEqual(osc.quadPhaseValue(), -0.25);
    SamplesEqual(osc.value(), -0.50);
    SamplesEqual(osc.quadPhaseValue(),  0.00);
    SamplesEqual(osc.value(), -0.25);
    SamplesEqual(osc.quadPhaseValue(),  0.25);
    SamplesEqual(osc.value(),  0.00);
    SamplesEqual(osc.quadPhaseValue(),  0.50);
    SamplesEqual(osc.value(),  0.25);
    SamplesEqual(osc.quadPhaseValue(),  0.75);
    SamplesEqual(osc.value(),  0.50);
    SamplesEqual(osc.quadPhaseValue(), -1.00);
    SamplesEqual(osc.value(),  0.75);
    SamplesEqual(osc.quadPhaseValue(), -0.75);
    SamplesEqual(osc.value(), -1.00);
    SamplesEqual(osc.quadPhaseValue(), -0.50);
}

- (void)testSinusoidAccuracy {
    LFO<double> osc(360.0, 1.0, LFO<double>::Waveform::sinusoid);
    osc.initialize(360.0, 1.0);
    for (int index = 0; index < 360.0; ++index) {
        auto theta = 2 * M_PI * index / 360.0;
        auto real = ::sin(theta);
        XCTAssertEqualWithAccuracy(osc.value(), real, 0.0011);
    }
}

@end
