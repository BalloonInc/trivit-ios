//
//  WKTableVIewRowController.h
//  trivit
//
//  Created by Wouter on 20/11/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//
@import WatchKit;

#import <Foundation/Foundation.h>

@interface WKTableVIewRowController : NSObject
@property (nonatomic) NSInteger count;

- (void)setItemName:(NSString *)text;
- (void)setTextColorCountLabel:(UIColor *)color;
- (void)setBackgroundColorCell:(UIColor *)color;
- (void)setCounter:(NSInteger)count;
- (void)hideCounter:(Boolean)hide;

@end
