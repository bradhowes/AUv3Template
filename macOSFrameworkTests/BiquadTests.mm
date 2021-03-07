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

- (void)testDefaultCoefficients {
    Biquad::Coefficients zeros;
    XCTAssertEqualWithAccuracy(0.0, zeros.a0, _epsilon);
    XCTAssertEqualWithAccuracy(0.0, zeros.a1, _epsilon);
    XCTAssertEqualWithAccuracy(0.0, zeros.a2, _epsilon);
    XCTAssertEqualWithAccuracy(0.0, zeros.b1, _epsilon);
    XCTAssertEqualWithAccuracy(0.0, zeros.b2, _epsilon);
    XCTAssertEqualWithAccuracy(1.0, zeros.c0, _epsilon);
    XCTAssertEqualWithAccuracy(0.0, zeros.d0, _epsilon);
}

- (void)testCoefficients {
    Biquad::Coefficients coefficients = Biquad::Coefficients()
    .A0(1.0)
    .A1(2.0)
    .A2(3.0)
    .B1(4.0)
    .B2(5.0)
    .C0(6.0)
    .D0(7.0);
    XCTAssertEqualWithAccuracy(1.0, coefficients.a0, _epsilon);
    XCTAssertEqualWithAccuracy(2.0, coefficients.a1, _epsilon);
    XCTAssertEqualWithAccuracy(3.0, coefficients.a2, _epsilon);
    XCTAssertEqualWithAccuracy(4.0, coefficients.b1, _epsilon);
    XCTAssertEqualWithAccuracy(5.0, coefficients.b2, _epsilon);
    XCTAssertEqualWithAccuracy(6.0, coefficients.c0, _epsilon);
    XCTAssertEqualWithAccuracy(7.0, coefficients.d0, _epsilon);
}

- (void)testNOP {
    Biquad::Coefficients zeros;
    Biquad::Direct foo(zeros);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(10.0), _epsilon);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(20.0), _epsilon);
    XCTAssertEqualWithAccuracy(0.0, foo.transform(30.0), _epsilon);
}

- (void)testLPF2Coefficients {
    // Test values taken from https://www.earlevel.com/main/2013/10/13/biquad-calculator-v2/
    double sampleRate = 44100.0;
    Biquad::Coefficients coefficients = Biquad::Coefficients::LPF2(sampleRate, 3000.0, 0.707);
    XCTAssertEqualWithAccuracy(0.03478485, coefficients.a0, _epsilon);
    XCTAssertEqualWithAccuracy(0.06956969, coefficients.a1, _epsilon);
    XCTAssertEqualWithAccuracy(0.03478485, coefficients.a2, _epsilon);
    XCTAssertEqualWithAccuracy(-1.40745716, coefficients.b1, _epsilon);
    XCTAssertEqualWithAccuracy(0.54659654, coefficients.b2, _epsilon);
}

- (void)testHPF2Coefficients {
    // Test values taken from https://www.earlevel.com/main/2013/10/13/biquad-calculator-v2/
    double sampleRate = 44100.0;
    Biquad::Coefficients coefficients = Biquad::Coefficients::HPF2(sampleRate, 3000.0, 0.707);
    XCTAssertEqualWithAccuracy(0.73851343, coefficients.a0, _epsilon);
    XCTAssertEqualWithAccuracy(-1.47702685, coefficients.a1, _epsilon);
    XCTAssertEqualWithAccuracy(0.73851343, coefficients.a2, _epsilon);
    XCTAssertEqualWithAccuracy(-1.40745716, coefficients.b1, _epsilon);
    XCTAssertEqualWithAccuracy(0.54659654, coefficients.b2, _epsilon);
}

- (void)testReset {
    double sampleRate = 44100.0;
    Biquad::Coefficients coefficients = Biquad::Coefficients::LPF1(sampleRate, 8000.0);
    Biquad::Direct filter(coefficients);
    XCTAssertEqualWithAccuracy( 0.00000, filter.transform(0.0), _epsilon);
    XCTAssertEqualWithAccuracy( 0.39056, filter.transform(1.0), _epsilon);
    filter.reset();
    XCTAssertEqualWithAccuracy( 0.00000, filter.transform(0.0), _epsilon);
}

@end
