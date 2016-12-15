//
//  SerialNumberGenerator.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "SerialNumberGenerator.h"

@implementation SerialNumberGenerator

+ (NSString*)newSerialWithSeed:(unsigned long long)initialSeed
{
    // get current time in seconds since the Epoch
    NSDate *now = [NSDate date];
    NSTimeInterval nowEpochSeconds = [now timeIntervalSince1970];
    
    // run current time through the lcg to create more randomness in seed
    long long lcgTimeResult = [self linearCongruentialGeneratorWithSeed:nowEpochSeconds];
    
    // couple with initial seed for even more randomness
    unsigned long long seed = initialSeed + lcgTimeResult;

    // generate pseudo-random serial number
    unsigned long long lcgResult = [self linearCongruentialGeneratorWithSeed:seed];
    
    // prepend '10' to serial number and convert to string
    NSString *ser = [NSString stringWithFormat:@"10%llu", lcgResult];

    // append zeroes to serial number until it is 15 digits long
    // note: if you pick a different length, you'll need to pick a different prime number
    // in the linearCongruentialGeneratorWithSeed method.
    for (int i=(int)[ser length]; i<15; i++) {
        ser = [NSString stringWithFormat:@"%@0", ser];
    }

    return ser;
}

/*
 * Generates a pseudo-randomized number calculated with a discontinuous piecewise linear equation.
 * The number generated will be less than the value of prime.
 */
+ (long long)linearCongruentialGeneratorWithSeed:(unsigned long long)seed
{
    long long prime = 9999999999971;
    int multiplier = 1013904223;
    int increment = 1664525;

    unsigned long long lcgResult = (seed * multiplier + increment) % prime;
    return lcgResult;
}

@end
