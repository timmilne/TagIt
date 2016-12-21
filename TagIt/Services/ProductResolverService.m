//
//  ProductResolverService.m
//  TagIt
//
//  Created by Christopher.Olsen on 11/23/16.
//  Copyright © 2016 Tim.Milne. All rights reserved.
//

#import "ProductResolverService.h"
#import "Product.h"

@implementation ProductResolverService

+ (void)getT2idWithBarcode:(NSString*)barcode andCompletion:(void (^)(NSError *error, NSArray *productList))completion {
    NSString *postString = [NSString stringWithFormat:
                            @"{"
                            "  \"query\": \"{findByVal_ProductLookup(val: \\\"%@\\\") {"
                            "      type: __typename"        // BARCODE or T2Id
                            "      ... on BARCODE {"
                            "        brcdVal: val"          // The barcode (original UPC)
                            "        t2Ids {"
                            "          t2IdVal: val"        // The T2Id
                            "          description"
                            "          primaryImage"
                            "          variation"           // If available, a json blob containing size, color, etc.
                            "        }"
                            "      }"
                            "    }"
                            "  }\""
                            "}",
                            barcode];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL: [NSURL URLWithString:@"http://40.83.191.150:8082/graphql"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postString length]]
        forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSession *session = [NSURLSession sharedSession];

    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
      {
          NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
          if (error || statusCode != 200) {
              completion(error, nil);
          } else {
              completion(nil, [self parseProductsFromArray:data]);
          }
      }] resume];
}

+ (NSArray*)parseProductsFromArray:(NSData*)data {
    NSError *jsonParsingError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParsingError];
    NSDictionary *productLookupDictionary = [json objectForKey:@"data"];
    NSArray *productLookupArray = [productLookupDictionary objectForKey:@"findByVal_ProductLookup"];
    NSDictionary *productLookup = [productLookupArray objectAtIndex:0];
    NSArray *t2Ids = [productLookup objectForKey:@"t2Ids"];

    // convert array of NSDictionaries into an array of Products
    NSMutableArray* products = [[NSMutableArray alloc] init];
    for (int i = 0; i < t2Ids.count; i++) {
        [products addObject:[[Product alloc] initWithJson:[t2Ids objectAtIndex:i]]];
    }

    return products;
}

+ (void)getTcinFromRedSkyWithBarcode:(NSString*)barcode andCompletion:(void (^)(NSError *error, NSArray *tcins))completion {
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
              completion(nil, [ProductResolverService parseTcinsFromArray:json]);
          }
      }] resume];
}

+ (NSArray*)parseTcinsFromArray:(NSArray*)jsonData {
    NSMutableArray *tcins = [[NSMutableArray alloc] init];
    for (int i = 0; i < jsonData.count; i++) {
        NSDictionary *item = [jsonData objectAtIndex:i];
        [tcins addObject:[item objectForKey:@"tcin"]];
    }

    return tcins;
}

+ (void)getProductImageWithUrl:(NSString*)url withCompletion:(void (^)(NSError *error, UIImage *image))completion
{
    NSURLSession *session = [NSURLSession sharedSession];

    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
      {
          if (error) {
              completion(error, nil);
          } else {
              completion(nil, [UIImage imageWithData:data]);
          }
      }] resume];
}

@end
