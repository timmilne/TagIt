//
//  TcinResolverService.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "TcinResolverService.h"

@implementation TcinResolverService

+ (void)getTcinWithBarcode:(NSString*)barcode andCompletion:(void (^)(NSError *error, NSArray *tcins))completion
{
    NSString *urlString = [NSString stringWithFormat:@"https://www.tgtappdata.com/v1/products/pdp/barcode/%@", barcode];

    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSURLQueryItem *apikey = [NSURLQueryItem queryItemWithName:@"key" value:@"6bf34d7581ae95886036b732"];
    components.queryItems = @[apikey];
    NSURL *url = components.URL;

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"X-REQUIRE-STORE-INFO" forHTTPHeaderField:@"true"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSURLSession *session = [NSURLSession sharedSession];

    [[session dataTaskWithURL:[NSURL URLWithString:urlString]
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
      {
          NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
          if (error || statusCode != 200) {
              completion(error, nil);
          } else {
              NSError *jsonParsingError = nil;
              NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
              completion(nil, [TcinResolverService parseTcinsFromArray:json]);
          }
      }] resume];
}

+ (NSArray*)parseTcinsFromArray:(NSArray*)jsonData
{
    NSMutableArray *tcins = [[NSMutableArray alloc] init];
    for (int i = 0; i < jsonData.count; i++) {
        NSDictionary *item = [jsonData objectAtIndex:i];
        [tcins addObject:[item objectForKey:@"tcin"]];
    }

    return tcins;
}

@end
