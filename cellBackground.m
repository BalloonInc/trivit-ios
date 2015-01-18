//
//  cellBackground.m
//  trivit
//
//  Created by Wouter Devriendt on 18/01/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "cellBackground.h"
#import "TrivitTableViewCell.h"
@implementation cellBackground

-(void) drawRect:(CGRect)rect{
    [super drawRect:rect];
    UIBezierPath *trianglePath = [UIBezierPath bezierPath];
    [trianglePath moveToPoint:CGPointMake(10.0, 0.0 + CELL_HEIGHT_SECTION1)];
    [trianglePath addLineToPoint:CGPointMake(20.0, 10.0 + CELL_HEIGHT_SECTION1)];
    [trianglePath addLineToPoint:CGPointMake(30.0, 0.0 + CELL_HEIGHT_SECTION1)];
    [trianglePath closePath];
    [[self cellBackColor] setFill];
    [trianglePath fill];
}

@end
