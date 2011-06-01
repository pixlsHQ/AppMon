//
//  AppStoreTests.m
//  AppMon
//
//  Created by Francis Chong on 11年5月30日.
//  Copyright 2011年 Ignition Soft Limited. All rights reserved.
//

#import "AppStoreApiTests.h"
#import "App.h"
#import "Review.h"
#import "AppStoreApi.h"

@implementation AppStoreApiTests

@synthesize appStore=_appStore;

- (void)setUp {
    [super setUp];
    self.appStore = [AppStoreApi sharedAppStoreApi];
}

- (void)tearDown {
    self.appStore = nil;
    [super tearDown];
}

- (void)testFetchAppById {
    NSError* error = nil;
    App* app = [self.appStore fetchAppByStore:@"143441" appId:@"343200656" error:&error]; // 343200656 = Angry Bird

    STAssertNil(error, @"should have no error");
    STAssertNotNil(app, @"should not nil");

    STAssertNotNil(app.title, @"title should not nil");
    STAssertNotNil(app.itemId, @"itemId should not nil");
    STAssertNotNil(app.url, @"url should not nil");
    STAssertNotNil(app.iconUrl, @"iconUrl should not nil");
    STAssertNotNil(app.price, @"price should not nil");
    STAssertNotNil(app.releaseDate, @"releaseDate should not nil");    
}


- (void)testSearchApp {
    NSError* error = nil;
    NSInteger count = 0;
    NSArray* apps = [self.appStore searchByStore:@"143441" query:@"Camera" page:0 total:&count error:&error];

    STAssertNil(error, @"should have no error");
    STAssertNotNil(apps, @"should not nil");
    STAssertTrue([apps count] > 5, @"should have at least 5 result items");
    NSLog(@"result count: %ld, total result count: %ld", [apps count], count);
    
    App* app = [apps objectAtIndex:0];
    STAssertNotNil(app, @"should not nil");
    STAssertNotNil(app.title, @"title should not nil");
    STAssertNotNil(app.itemId, @"itemId should not nil");
    STAssertNotNil(app.url, @"url should not nil");
    STAssertNotNil(app.iconUrl, @"iconUrl should not nil");
    STAssertNotNil(app.price, @"price should not nil");
    STAssertNotNil(app.releaseDate, @"releaseDate should not nil");    
}
- (void)testSearchAppSecondPage {
    NSError* error = nil;
    NSInteger count = 0;
    NSArray* apps2 = [self.appStore searchByStore:@"143441" query:@"Camera" page:1 total:&count error:&error];
    STAssertNil(error, @"should have no error searching second page");
    STAssertNotNil(apps2, @"should not nil");
    STAssertTrue([apps2 count] > 5, @"should have at least 5 result items");
}


- (void)testReviews {
    NSError* error = nil;
    NSInteger total = 0;
    NSDate* lastReviewDate = nil;
    NSArray* reviews = [self.appStore reviewsByStore:@"143441" appId:@"343200656" page:0 total:&total lastReviewDate:&lastReviewDate error:&error];
    STAssertNil(error, @"should have no error: %@", error);
    
    STAssertNotNil(reviews, @"should not nil");
    STAssertTrue([reviews count] > 0, @"should have at least 1 comments");
    STAssertNotNil(lastReviewDate, @"lastReviewDate should not be nil");
    STAssertTrue(total > 0, @"should have total > 0");
    STAssertTrue(total < 1000000, @"should have total < 1000000");
    
    Review* rev = [reviews objectAtIndex:0];
    STAssertNotNil(rev.title, @"should have title");
    STAssertNotNil(rev.text, @"should have text");
    STAssertTrue(rev.rating > 0, @"should have rating");
    
    NSLog(@"rev: %@", [rev description]);
    
    // HKTV
    reviews = [self.appStore reviewsByStore:@"143441" appId:@"348883035" page:0 total:&total lastReviewDate:&lastReviewDate error:&error];
    STAssertNil(error, @"should have no error: %@", error);
    STAssertTrue(total > 0, @"should have total > 0");
    STAssertTrue(total < 1000000, @"should have total < 1000000");
    
}

- (void)testCountry {
    NSError* error = nil;
    NSArray* stores = [self.appStore stores:&error];
    STAssertNil(error, @"should have no error");
  
    STAssertNotNil(stores, @"should not nil");
    STAssertTrue([stores count] > 0, @"should have at least 1 comments");
}

@end
