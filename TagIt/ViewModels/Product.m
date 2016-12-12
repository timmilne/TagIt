//
//  Product.m
//  TagIt
//
//  Created by Christopher.Olsen on 12/12/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "Product.h"
#import "ProductResolverService.h"

@implementation Product

#pragma mark custom setters

- (void)setProductImageName:(NSString *)input;
{
    productImageName = input;

    [ProductResolverService getProductImageWithUrl:input withCompletion:^(NSError *error, UIImage *image) {
        self.productImage = image;
        [self.delegate productImageLoaded:self.productId];
    }];
}

@synthesize productDescription;
@synthesize productId;
@synthesize productVariantBlob;
@synthesize productImageName;
@synthesize productImage;

- (id)initWithJson:(NSDictionary *)json {
    self = [super init];

    if (self) {
        self.productDescription = [json objectForKey:@"description"];
        self.productId = [json objectForKey:@"t2id"];
        self.productVariantBlob = [json objectForKey:@"variants"];
        self.productImageName = [json objectForKey:@"image"];
    }

    return self;
}

@end
