//
//  TcinSelectViewController.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/28/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "ProductSelectViewController.h"
#import "ProductTableViewCell.h"
#import "Product.h"

@interface ProductSelectViewController ()

@property (nonatomic) NSInteger selectedPath;

@end

@implementation ProductSelectViewController

static NSString * const reuseIdentifier = @"ProductCell";

@synthesize delegate;
@synthesize products;
@synthesize selectedPath;

#pragma mark iOS View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark Utility Methods

- (int)findProductIndex:(NSString *)productId {
    int index = -1;

    for (int i = 0; i < self.products.count; i++) {

        if ([((Product *)[self.products objectAtIndex:i]).productId isEqualToString:productId])
        {
            index = i;
            break;
        }
    }

    return index;
}

- (void) generateProductInfoAlertWithIndex:(int)index {
    Product *product = [products objectAtIndex:index];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:product.productDescription
                                                            message:[NSString stringWithFormat:@"T2ID:\n%@\nProduct Variants\n%@", product.productId, product.productVariantBlob]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"select" style:UIAlertActionStyleDefault handler:^void (UIAlertAction *action)
                                   {
                                       self.selectedPath = index;
                                       [self selectProductAndDismissController];
                                   }];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"dismiss" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:selectAction];
    [alertController addAction:dismissAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)selectProductAndDismissController {
    [self dismissViewControllerAnimated:YES completion:nil];
    [delegate selectionMadeWithProduct:[products objectAtIndex:selectedPath]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return products.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        [self.tableView registerNib:[UINib nibWithNibName:@"ProductTableViewCell" bundle:nil] forCellReuseIdentifier:reuseIdentifier];
        cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    }

    Product *product = [products objectAtIndex:indexPath.row];
    product.delegate = self;
    [cell setupCellWithDescription:product.productDescription andId:product.productId andImage:product.productImage];
    cell.delegate = self;
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 142.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedPath = indexPath.row;
    [self selectProductAndDismissController];
}

#pragma mark - ProductDelegate

- (void)productImageLoaded:(NSString *)productId {
    int index = [self findProductIndex:productId];
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

#pragma mark - ProductTableViewCellDelegate

- (void)cellMoreInfoButtonPressed:(NSString *)productId {
    [self generateProductInfoAlertWithIndex:[self findProductIndex:productId]];
}

@end
