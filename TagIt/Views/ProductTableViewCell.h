//
//  TcinTableViewCell.h
//  TagIt
//
//  Created by Christopher.Olsen on 12/8/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductTableViewCellDelegate.h"

@interface ProductTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property (weak, nonatomic) IBOutlet UILabel *productDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *productIdLabel;

@property (weak, nonatomic) id <ProductTableViewCellDelegate> delegate;

- (IBAction)moreInfo:(id)sender;

- (void)setupCellWithDescription:(NSString *)description andId:(NSString *)tcin andImage:(UIImage *) image;

@end
