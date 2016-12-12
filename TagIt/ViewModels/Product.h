//
//  Product.h
//  TagIt
//
//  Created by Christopher.Olsen on 12/12/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductDelegate.h"

@interface Product : NSObject

@property (nonatomic) NSString *productDescription;
@property (nonatomic) NSString *productId;
@property (nonatomic) NSString *productVariantBlob;
@property (nonatomic) NSString *productImageName;
@property (nonatomic) UIImage *productImage;

@property (nonatomic, weak) id <ProductDelegate> delegate;

- (id)initWithJson:(NSDictionary *)json;

@end
