//
//  WKTableVIewRowController.m
//  trivit
//
//  Created by Wouter on 20/11/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "WKTableVIewRowController.h"
@interface WKTableVIewRowController()
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *itemCountButton;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *completeCell;

@end
@implementation WKTableVIewRowController

- (void)setItemName:(NSString *)text{
    [self.itemNameLabel setText:[NSString stringWithFormat:@" %@", text ]];
}
- (void)setBackgroundColorButton:(UIColor *)color{
    [self.itemCountButton setBackgroundColor:color];
}
- (void)setBackgroundColorCell:(UIColor *)color{
    [self.completeCell setBackgroundColor:color];
}
- (void)setCounter:(NSInteger)count{
    [self.itemCountButton setTitle:[NSString stringWithFormat:@"%ld",(long)count ]];
}

@end
