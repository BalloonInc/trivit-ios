//
//  PaddingUITextField.m
//  trivit
//
//  Created by Pieterjan Criel on 2/08/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "PaddingUITextField.h"

@implementation PaddingUITextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
//    return CGRectInset(bounds, 50.0f, 0);
    return CGRectMake(10, 0, bounds.size.width-70, bounds.size.height);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end
