//
//  DetailInterfaceController.h
//  trivit
//
//  Created by Wouter Devriendt on 05/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>


@interface DetailInterfaceController : WKInterfaceController <WCSessionDelegate>

@property (strong, nonatomic) NSString *title;
@property (nonatomic) NSInteger count;
@property (strong, nonatomic) UIColor *lightColor;
@property (strong, nonatomic) UIColor *darkColor;

@end
