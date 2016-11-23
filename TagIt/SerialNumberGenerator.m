//
//  SerialNumberGenerator.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "SerialNumberGenerator.h"

@implementation SerialNumberGenerator

+ (NSString*)newSerialWithSeed:(long long) initialSeed
{
    // get current time in seconds since the Epoch
    NSDate *now = [NSDate date];
    NSTimeInterval nowEpochSeconds = [now timeIntervalSince1970];
    // run current time through the lcg to create more randomness in seed
    long long lcgTimeResult = [self linearCongruentialGeneratorWithSeed:nowEpochSeconds];

    long long seed = initialSeed + lcgTimeResult;

    // generate pseudo-random serial number
    unsigned long long lcgResult = [self linearCongruentialGeneratorWithSeed:seed];
    // prepend '10' to serial number and convert to string

    NSString *ser = [NSString stringWithFormat:@"10%llu", lcgResult];

    // append zeroes to serial number until it is 15 digits long
    if ([ser length] < 15) {
        short counter = 15 - [ser length];
        for (int i = 0; i < counter; i++) {
            ser = [NSString stringWithFormat:@"%@0", ser];
        }
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
