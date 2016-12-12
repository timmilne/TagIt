//
//  TcinSelectViewController.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/28/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "TcinSelectViewController.h"
#import "TcinTableViewCell.h"
#import "Product.h"

@interface TcinSelectViewController ()

@property (nonatomic) NSIndexPath *selectedPath;

@end

@implementation TcinSelectViewController

static NSString * const reuseIdentifier = @"TcinCell";

@synthesize delegate;
@synthesize products;
@synthesize selectedPath;

#pragma mark IBAction Implementations

- (IBAction)doneSelecting:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [delegate selectionMadeWithProduct:[products objectAtIndex:selectedPath.row]];
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
    return products.count;
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

    Product *product = [products objectAtIndex:indexPath.row];
    product.delegate = self;
    [cell setupCellWithDescription:product.productDescription andTcin:product.productId andImage:product.productImage];
    
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

#pragma mark - ProductDelegate

- (void) productImageLoaded:(NSString *)productId {
    int index = -1;

    for (int i = 0; i < self.products.count; i++) {

        if ([((Product *)[self.products objectAtIndex:i]).productId isEqualToString:productId])
        {
            index = i;
            break;
        }
    }

    NSArray *indexes = [self.tableView indexPathsForVisibleRows];

    for (NSIndexPath *indexPath in indexes) {
        if (indexPath.row == index) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            });
        }
    }
}

@end
