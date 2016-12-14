//
//  ProductDelegate.h
//  TagIt
//
//  Created by Christopher.Olsen on 12/12/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProductDelegate <NSObject>

- (void) productImageLoaded:(NSString *)productId;

@end
