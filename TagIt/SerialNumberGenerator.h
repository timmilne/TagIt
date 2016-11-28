//
//  SerialNumberGenerator.h
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SerialNumberGenerator : NSObject

+ (NSString*)newSerialWithSeed:(unsigned long long) initialSeed;

@end
