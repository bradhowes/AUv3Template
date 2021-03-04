// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#import "Biquad.h"

@interface BiquadTests : XCTestCase
@property float epsilon;
@end

@implementation BiquadTests

- (void)setUp {
    _epsilon = 0.0001;
}

- (void)testNOP {
    Biquad::Coefficients zeros;
    Biquad::Direct foo(zeros);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(10.0), _epsilon);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(20.0), _epsilon);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(30.0), _epsilon);
}

- (void)testLPF1 {
    double sampleRate = 41500.0;
    Biquad::Coefficients coefficients = Biquad::Coefficients::LPF1(sampleRate, 8000.0);
    Biquad::Direct filter(coefficients);
    XCTAssertEqualWithAccuracy( 0.00000, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.40912, filter.transform(1.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.48348, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.32125, filter.transform(-1.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.46751, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.32415, filter.transform(1.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.46804, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.32406, filter.transform(-1.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.46802, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.32406, filter.transform(1.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.46802, filter.transform(0.0), _epsilon);
}

- (void)testHPF1 {
    double sampleRate = 41500.0;
    Biquad::Coefficients coefficients = Biquad::Coefficients::HPF1(sampleRate, 8000.0);
    Biquad::Direct filter(coefficients);
    XCTAssertEqualWithAccuracy( 0.00000, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.59088, filter.transform(1.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.48348, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.67875, filter.transform(-1.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.46751, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.67585, filter.transform(1.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.46804, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.67594, filter.transform(-1.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.46802, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.67594, filter.transform(1.0), _epsilon);
    XCTAssertEqualWithAccuracy(-0.46802, filter.transform(0.0), _epsilon);
}

- (void)testReset {
    double sampleRate = 41500.0;
    Biquad::Coefficients coefficients = Biquad::Coefficients::LPF1(sampleRate, 8000.0);
    Biquad::Direct filter(coefficients);
    XCTAssertEqualWithAccuracy( 0.00000, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.40912, filter.transform(1.0), _epsilon);
    filter.reset();
    XCTAssertEqualWithAccuracy( 0.00000, filter.transform(0.0), _epsilon);
}

@end
