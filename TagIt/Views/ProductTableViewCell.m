//
//  ProductTableViewCell.m
//  TagIt
//
//  Created by Christopher.Olsen on 12/8/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "ProductTableViewCell.h"

@implementation ProductTableViewCell

@synthesize delegate;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)moreInfo:(id)sender {
    [delegate cellMoreInfoButtonPressed:self.productIdLabel.text];
}

- (void)setupCellWithDescription:(NSString *)description andId:(NSString *)t2id andImage:(UIImage *)image
{
    self.productDescriptionLabel.text = description;
    self.productIdLabel.text = t2id;
    self.productImageView.image = image;
}

@end
