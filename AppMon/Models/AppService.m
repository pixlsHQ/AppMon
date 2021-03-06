//
//  AppService.m
//  AppMon
//
//  Created by Francis Chong on 11年5月31日.
//  Copyright 2011年 Ignition Soft Limited. All rights reserved.
//

#import "AppService.h"
#import "SynthesizeSingleton.h"

#import "App.h"
#import "AppStoreApi.h"
#import "AppMonAppDelegate.h"
#import "Timeline.h"
#import "AppMonConfig.h"

NSString * const AppServiceNotificationTimelineChanged  = @"hk.ignition.mac.appmon.TimelineChanged";
NSString * const AppServiceNotificationReadApp          = @"hk.ignition.mac.appmon.ReadApp";
NSString * const AppServiceNotificationStoreChanged     = @"hk.ignition.mac.appmon.StoreChanged";

NSString * const AppServiceNotificationFollowedApp      = @"hk.ignition.mac.appmon.FollowedApp";
NSString * const AppServiceNotificationUnfollowedApp    = @"hk.ignition.mac.appmon.UnfollowedApp";

NSString * const AppServiceNotificationFetchNoUpdate    = @"hk.ignition.mac.appmon.fetchnoupdate";
NSString * const AppServiceNotificationFetchFinished    = @"hk.ignition.mac.appmon.fetchfinished";
NSString * const AppServiceNotificationFetchFailed      = @"hk.ignition.mac.appmon.fetchfailed";

@interface AppService (Private)
-(NSString*) saveFilePath;
@end

@implementation AppService

SYNTHESIZE_SINGLETON_FOR_CLASS(AppService);

@synthesize stores=_stores;

- (id)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("hk.ignition.appmon", NULL);
        
        _timelines = [[NSMutableDictionary dictionary] retain];

        _stores = [[[AppMonConfig sharedAppMonConfig] enabledStores] retain];

        [self load];
        
    }
    
    return self;
}

- (void)dealloc
{
    dispatch_release(_queue);

    [_timelines release];
    _timelines = nil;

    [_apps release];
    _apps = nil;
    
    [_stores release];
    _stores = nil;
    
    [super dealloc];
}

-(void) follow:(App*)app {
    if (![self isFollowed:app]) {
        [_apps addObject:app];
        [_apps sortWithOptions:0 usingComparator:^(id id1, id id2){
            App* app1 = id1;
            App* app2 = id2;            
            return [app1.title compare:app2.title];
        }];
        [self save];
        [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationFollowedApp 
                                                            object:app];
    }
}

-(void) unfollow:(App*)app {
    [_apps removeObject:app];
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationUnfollowedApp 
                                                        object:app];
}

-(NSArray*) followedApps {
    return _apps;
}

-(NSUInteger) unreadCount {
    NSUInteger totalUnreadCount = 0;

    if (_timelines) {
        for (Timeline* tl in [[[_timelines allValues] copy] autorelease]) {
            totalUnreadCount += tl.unread;
        }
    }

    return totalUnreadCount;
}

-(BOOL) isFollowed:(App*)app {
    return [_apps containsObject:app];
}

-(void) setStores:(NSArray*)newStores {
    @synchronized(_stores) {
        [_stores release];
        _stores = [newStores retain];
        
        for (Timeline* tl in [_timelines allValues]) {
            [tl reset];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationStoreChanged
                                                            object:self];
    }
}

@end

@implementation AppService (Timeline)

-(void) fetchTimelineWithApp:(App*)app {
    [self fetchTimelineWithApp:app more:NO];
}

-(void) fetchTimelineWithApp:(App*)app more:(BOOL)loadMore {
    if (loadMore) {
        NSLog(@"fetch more timeline with app: %@", app.title);
    } else {
        NSLog(@"fetch timeline with app: %@ (%ld)", app.title, app.total);        
    }
    
    Timeline* timeline = [self timelineWithApp:app];

    dispatch_async(_queue, ^{
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        NSInteger prevTotal         = [timeline total];
        AppStoreApi* api            = [AppStoreApi sharedAppStoreApi];
        NSArray* reviewResponses    = nil;

        NSMutableDictionary* previousReviewResponseMap = [NSMutableDictionary dictionary];
        NSArray* previousReviewResponse = [timeline responsesWithStoresWithMoreReviews];
        for (ReviewResponse* resp in previousReviewResponse) {
            [previousReviewResponseMap setValue:resp forKey:resp.store];
        }

        if (loadMore) {
            reviewResponses = [api reviewsByResponses:previousReviewResponse];
        } else {
            reviewResponses = [api reviewsByStores:self.stores 
                                             appId:app.itemId];

        }
        
        BOOL changed = NO;
        for (ReviewResponse* reviewResp in reviewResponses) {
            if (reviewResp.error) {
                NSLog(@"timeline of (%@) encounter error: %@", app.title, reviewResp.error);
                [timeline setResponse:reviewResp withStore:reviewResp.store];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationFetchFailed
                                                                        object:reviewResp];
                });
            } else {
                NSString* store = reviewResp.store;
                ReviewResponse* prevReviewResp = [previousReviewResponseMap objectForKey:store];
                if (loadMore ||
                    prevReviewResp == nil ||
                    [[prevReviewResp lastReviewDate] compare:[reviewResp lastReviewDate]] == NSOrderedAscending) {
                    [timeline addReviews:reviewResp.reviews];
                    [timeline setResponse:reviewResp withStore:store];
                    
                    if ([timeline lastReviewDate] == nil || [[timeline lastReviewDate] compare:[reviewResp lastReviewDate]] == NSOrderedAscending) {
                        [timeline setLastReviewDate:[reviewResp lastReviewDate]];
                    }

                    changed = YES;
                }
            }

        } // for each review responses

        if (!loadMore && changed && (timeline.total - prevTotal > 0)) {
            timeline.unread = timeline.unread + timeline.total - prevTotal;
            
        }
  
        if (changed) {
            [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationTimelineChanged
                                                                object:timeline];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationFetchFinished
                                                                    object:timeline];                
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationFetchNoUpdate
                                                                    object:timeline];
            });
        }
        [pool release];
    });
}

-(void) markAppAsRead:(App*)app {
    app.unread = 0;
    [self save];

    [[NSNotificationCenter defaultCenter] postNotificationName:AppServiceNotificationReadApp 
                                                        object:app];
    
}

-(Timeline*) timelineWithApp:(App*)app {   
    Timeline* timeline = [_timelines objectForKey:app.itemId];
    if (!timeline) {        
        timeline = [[[Timeline alloc] initWithApp:app] autorelease];
        [_timelines setValue:timeline forKey:app.itemId];
    }

    return timeline;
}

@end

@implementation AppService (Persistence)

-(void) save {
    dispatch_async(_queue, ^{
        NSString* savePath = [self saveFilePath];
        if (!savePath) {
            NSLog(@"ERROR: Cannot save AppService: save path not available");
            return;
        }
        
        BOOL result = [NSKeyedArchiver archiveRootObject:_apps 
                                                  toFile:savePath];
        if (!result) {
            NSLog(@"WARN: Failed saving AppService: %@", savePath);
        }
    });
}

-(void) load {
    NSString* savePath = [self saveFilePath];
    if (!savePath) {
        NSLog(@"ERROR: Cannot load AppService: save path not available");
        return;
    }

    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:savePath]) {
        NSLog(@"Load config file: %@", savePath);
        [_apps release];
        _apps = [[NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:savePath]] retain];
        [_apps sortWithOptions:0 usingComparator:^(id id1, id id2){
            App* app1 = id1;
            App* app2 = id2;            
            return [app1.title compare:app2.title];
        }];
        NSLog(@" loaded: %@", _apps);
        return;
    }

    // create initial empty data record
    [_apps release];
    _apps = [[NSMutableArray array] retain];
    [self save];
}

// save path for app mon config file
// create intermediate directories if needed
-(NSString*) saveFilePath {
    NSBundle* bundle = [NSBundle mainBundle];
    NSDictionary* info = [bundle infoDictionary];
    NSString* bundleName = [info objectForKey:@"CFBundleName"];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true);
    NSString* path = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) {
        NSError* error = nil;
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"ERROR: Cannot create config file path: %@, error=%@", path, error);
            return nil;
        }
    }
    
    return [path stringByAppendingFormat:@"/appservice.plist"];   
}

@end
