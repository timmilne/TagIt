//
//  TcinTableViewCell.m
//  TagIt
//
//  Created by Christopher.Olsen on 12/8/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "TcinTableViewCell.h"

@implementation TcinTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCellWithDescription:(NSString *)description andTcin:(NSString *)tcin andImage:(UIImage *) image
{
    self.tcinDescription.text = description;
    self.tcin.text = tcin;
    self.tcinImageView.image = image;
}

@end
