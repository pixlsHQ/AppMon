//
//  ReviewResponse.h
//  AppMon
//
//  Created by Francis Chong on 11年6月3日.
//  Copyright 2011年 Ignition Soft Limited. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ReviewResponse : NSObject {
@private
    NSInteger   total;
    CGFloat     averageUserRating;
    NSInteger   ratingCount;
    
    NSArray*    reviews;
    NSDate*     lastReviewDate;
    NSString*   nextUrl;
    NSError*    error;
}

@property (nonatomic, assign) NSInteger     total;
@property (nonatomic, assign) CGFloat       averageUserRating;
@property (nonatomic, assign) NSInteger     ratingCount;

@property (nonatomic, retain) NSArray*      reviews;
@property (nonatomic, retain) NSDate*       lastReviewDate;
@property (nonatomic, retain) NSString*     moreUrl;

@property (nonatomic, retain) NSError*      error;

@end
