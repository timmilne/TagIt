//
//  TcinSelectViewController.h
//  TagIt
//
//  Created by Christopher.Olsen on 11/28/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductSelectDelegate.h"
#import "ProductDelegate.h"

@interface ProductSelectViewController : UITableViewController <ProductDelegate>

@property (nonatomic, weak) id <ProductSelectDelegate> delegate;
@property NSArray *products;

- (IBAction)doneSelecting:(id)sender;

@end
