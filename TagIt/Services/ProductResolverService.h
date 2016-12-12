//
//  TcinResolverService.h
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductResolverService : NSObject

+ (void)getTcinFromRedSkyWithBarcode:(NSString*)barcode andCompletion:(void (^)(NSError *error, NSArray *tcins))completion;
+ (void)getT2idWithBarcode:(NSString*)barcode andCompletion:(void (^)(NSError *error, NSArray *tcins))completion;
+ (void)getProductImageWithUrl:(NSString*)url withCompletion:(void (^)(NSError *error, UIImage *image))completion;

@end
