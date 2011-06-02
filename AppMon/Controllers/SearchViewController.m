//
//  SearchViewController.m
//  AppMon
//
//  Created by Chong Francis on 11年5月31日.
//  Copyright 2011年 Ignition Soft Limited. All rights reserved.
//

#import "SearchViewController.h"
#import "AppSearchResultItem.h"
#import "AppSearchHeaderItem.h"
#import "AppMonAppDelegate.h"
#import "AppService.h"

@interface SearchViewController (Private)
-(void) searchDidFinished:(NSArray*)results;
-(void) searchDidFailed:(NSError*)error;
-(NSString*) store;
@end

@implementation SearchViewController

@synthesize searchScrollView=_searchScrollView, progressIndicator=_progressIndicator, searchResultList=_searchResultList;
@synthesize api=_api, appService=_appService, results=_results;
@synthesize searchNotFoundView=_searchNotFoundView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

- (void)dealloc
{
    self.appService = nil;
    self.api = nil;
    self.results = nil;
    [super dealloc];
}

-(void) awakeFromNib {
    [super awakeFromNib];
    
    self.appService = [AppService sharedAppService];
    self.api = [AppStoreApi sharedAppStoreApi];    
}

#pragma mark - Public

-(void) setNotFound:(BOOL)isNotFound {
    [self.searchNotFoundView setHidden:!isNotFound];
    [self.searchScrollView setHidden:isNotFound];
}

-(void) setLoading:(BOOL)isLoading {
    _loading = isLoading;
    if (isLoading) {
        [self.progressIndicator startAnimation:self];
    } else {
        [self.progressIndicator stopAnimation:self];
    }
    [self.progressIndicator setHidden:!isLoading];
    [self.searchResultList setHidden:isLoading];
}

-(void) search:(NSString*)query {
    NSLog(@"search: %@", query);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError* error = nil;
        NSInteger total;

        NSArray* searchResult = [self.api searchByStore:[self store]
                                                  query:query 
                                                   page:0 
                                                  total:&total 
                                                  error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setLoading:NO];
            if (error) {
                [self searchDidFailed:error];
            } else {
                [self searchDidFinished:searchResult];
            }
        });
    });
}

#pragma mark - Private

-(void) searchDidFinished:(NSArray*)theResults {
    if ([theResults count] == 0) {
        NSLog(@"no search result");
        [self setNotFound:YES];
    } else {
        NSLog(@"search finished: %@", theResults);
        [self setNotFound:NO];
        self.results = theResults;
        [self.searchResultList reloadDataAnimated:YES];
    }
}

-(NSString*) store {
    return @"143441"; // US
}

-(void) searchDidFailed:(NSError*)error {
    NSLog(@"search failed: %@", error);
}

#pragma mark - Actions

-(void) follow:(id)sender {
    AppSearchResultItem* item = (AppSearchResultItem*) [sender superview];
    
    NSLog(@"Follow App: %@", item.app);
    [self.appService follow:item.app];
    [item setFollowed:YES];
    [item setNeedsDisplay:YES];
    [[AppMonAppDelegate instance].mainController.appListViewController selectApp:item.app];
}

-(void) unfollow:(id)sender {
    AppSearchResultItem* item = (AppSearchResultItem*)  [sender superview];
    NSLog(@"Unfollow App: %@", item.app);
    [self.appService unfollow:item.app];
    [item setFollowed:NO];
    [item setNeedsDisplay:YES];
}

#pragma mark - JASectionedListViewDataSource

- (NSUInteger)numberOfSectionsInListView:(JASectionedListView *)listView {
    return 1;
}

- (NSUInteger)listView:(JASectionedListView *)listView numberOfViewsInSection:(NSUInteger)section {
    return [_results count];
}

- (JAListViewItem *)listView:(JAListView *)listView sectionHeaderViewForSection:(NSUInteger)section {
    AppSearchHeaderItem* item = [AppSearchHeaderItem item];
    [item.lblMessage setStringValue:[NSString stringWithFormat:@"%d search result loaded", [_results count]]];
    [item setHidden:_loading];
    return item;
}

- (JAListViewItem *)listView:(JAListView *)listView viewForSection:(NSUInteger)section index:(NSUInteger)index {
    AppSearchResultItem* item = [AppSearchResultItem item];
    App* app = [_results objectAtIndex:index];
    [item setApp:app];
    [item setFollowed:[self.appService isFollowed:app]];    
    [item.btnFollow setTarget:self];
    [item.btnFollow setAction:@selector(follow:)];    
    [item.btnUnfollow setTarget:self];
    [item.btnUnfollow setAction:@selector(unfollow:)];
    return item;
}


@end
