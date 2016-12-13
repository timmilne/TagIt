//
//  ProductTableViewCellDelegate.h
//  TagIt
//
//  Created by Christopher.Olsen on 12/13/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProductTableViewCellDelegate <NSObject>

- (void)cellMoreInfoButtonPressed:(NSString *)productId;

@end
