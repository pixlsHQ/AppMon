//
//  Review.m
//  AppMon
//
//  Created by Francis Chong on 11年5月30日.
//  Copyright 2011年 Ignition Soft Limited. All rights reserved.
//

#import "Review.h"


@implementation Review

@synthesize rating=_rating, text=_text, title=_title, username=_username, date=_date, position=_position, on_version=_on_version;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(id) initWithPlist:(NSDictionary*)plist {
    self = [super init];
    if (self) {
        self.rating     = [[plist objectForKey:@"average-user-rating"] doubleValue];
        self.text       = [plist objectForKey:@"text"];
        self.title      = [plist objectForKey:@"title"];
        self.username      = [plist objectForKey:@"user-name"];
           
    }
    return self;
}


- (void)dealloc
{
    
    self.text = nil;
    self.title = nil;
    self.username = nil;
    self.date = nil;
    self.on_version = nil;
    [super dealloc];
}

@end
