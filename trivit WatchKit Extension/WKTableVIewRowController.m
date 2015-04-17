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
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *itemCountLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *completeCell;

@end
@implementation WKTableVIewRowController

- (void)setItemName:(NSString *)text{
    [self.itemNameLabel setText:[NSString stringWithFormat:@" %@", text ]];
}
- (void)setTextColorCountLabel:(UIColor *)color{
    [self.itemCountLabel setTextColor:color];
}
- (void)setBackgroundColorCell:(UIColor *)color{
    [self.completeCell setBackgroundColor:color];
}
- (void)setCounter:(NSInteger)count{
    self.count=count;
    if (count>=0)
        [self.itemCountLabel setText:[NSString stringWithFormat:@"%ld",(long)count ]];
    else
        [self.itemCountLabel setText:@"-"];
}
-(void)hideCounter:(Boolean)hide{
    [self.itemCountLabel setHidden:hide];
}

@end
