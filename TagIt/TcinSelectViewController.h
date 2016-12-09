//
//  TcinSelectViewController.h
//  TagIt
//
//  Created by Christopher.Olsen on 11/28/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TcinSelectDelegate.h"

@interface TcinSelectViewController : UITableViewController

@property (nonatomic, weak) id <TcinSelectDelegate> delegate;
@property NSArray *tcins;

- (IBAction)doneSelecting:(id)sender;

@end
