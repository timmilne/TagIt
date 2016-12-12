//
//  EncoderViewController.h
//  TagIt
//
//  Created by Tim.Milne on 11/11/16.
//  Copyright (c) 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TcinSelectDelegate.h"
#import "Product.h"

@interface EncoderViewController : UIViewController <TcinSelectDelegate>

@property (nonatomic) Product *product;
@property (nonatomic) NSArray *products;

@end
