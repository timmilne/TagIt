//
//  ProductSelectDelegate.h
//  TagIt
//
//  Created by Christopher.Olsen on 12/9/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Product.h"

@protocol ProductSelectDelegate <NSObject>

- (void)selectionMadeWithProduct:(Product *)selectedProduct;

@end

