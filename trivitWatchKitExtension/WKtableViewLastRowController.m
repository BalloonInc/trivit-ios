//
//  WKtableViewLastRowController.m
//  trivit
//
//  Created by Wouter Devriendt on 21/03/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "WKtableViewLastRowController.h"
@interface WKtableViewLastRowController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *addTrivitLabel;
@end

@implementation WKtableViewLastRowController
- (void)setTextColorAddTrivitLabel:(UIColor *)color{
    [self.addTrivitLabel setTextColor:color];
}

@end
