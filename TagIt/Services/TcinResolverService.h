//
//  TcinResolverService.h
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TcinResolverService : NSObject

+ (void)getTcinFromRedSkyWithBarcode:(NSString*)barcode andCompletion:(void (^)(NSError *error, NSArray *tcins))completion;

@end
