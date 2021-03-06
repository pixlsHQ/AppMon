//
//  AppSearchHeaderItem.h
//  AppMon
//
//  Created by Francis Chong on 11年5月31日.
//  Copyright 2011年 Ignition Soft Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JAListViewItem.h"

@interface AppSearchHeaderItem : JAListViewItem {
@private
    NSTextField* _lblMessage;
    NSButton* _btnProceed;
    
}

@property (nonatomic, retain) IBOutlet NSTextField*     lblMessage;
@property (nonatomic, retain) IBOutlet NSButton*        btnProceed;

+ (AppSearchHeaderItem *) item;


@end
