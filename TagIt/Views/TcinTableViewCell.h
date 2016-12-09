//
//  TcinTableViewCell.h
//  TagIt
//
//  Created by Christopher.Olsen on 12/8/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TcinTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *tcinImageView;
@property (weak, nonatomic) IBOutlet UILabel *tcinDescription;
@property (weak, nonatomic) IBOutlet UILabel *tcin;

- (void)setupCellWithDescription:(NSString *)description andTcin:(NSString *)tcin andImage:(UIImage *) image;

@end
