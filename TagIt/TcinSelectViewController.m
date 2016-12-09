//
//  TcinSelectViewController.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/28/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "TcinSelectViewController.h"
#import "TcinTableViewCell.h"

@interface TcinSelectViewController ()

@property (nonatomic) NSIndexPath *selectedPath;

@end

@implementation TcinSelectViewController

static NSString * const reuseIdentifier = @"TcinCell";

@synthesize delegate;
@synthesize tcins;
@synthesize selectedPath;

#pragma mark IBAction Implementations

- (IBAction)doneSelecting:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [delegate selectionMadeWithTcin:[tcins objectAtIndex:selectedPath.row]];
}

#pragma mark iOS View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return tcins.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TcinTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        [self.tableView registerNib:[UINib nibWithNibName:@"TcinTableViewCell" bundle:nil] forCellReuseIdentifier:reuseIdentifier];
        cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    }

    if (indexPath.row == self.selectedPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    [cell setupCellWithDescription:@"Blah Blah Blah" andTcin:[tcins objectAtIndex:indexPath.row] andImage:nil];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 142.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedPath = indexPath;
    [self.tableView reloadData];
}

@end
