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

@property (nonatomic) NSMutableArray *_tcins;
@property (nonatomic) NSIndexPath *selectedPath;

@end

@implementation TcinSelectViewController

static NSString * const reuseIdentifier = @"TcinCell";

@synthesize _tcins;
@synthesize selectedPath;

#pragma mark IBAction Implementations

- (IBAction)doneSelecting:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark iOS View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    _tcins = [[NSMutableArray alloc] init];
    [_tcins addObject:@"89074567"];
    [_tcins addObject:@"12340876"];
    [_tcins addObject:@"56782458"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tcins.count;
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

    [cell setupCellWithDescription:@"Blah Blah Blah" andTcin:[_tcins objectAtIndex:indexPath.row] andImage:nil];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 142.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedPath = indexPath;
    [self.tableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
