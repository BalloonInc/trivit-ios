//
//  Counter.m
//  trivit
//
//  Created by Wouter Devriendt on 25/06/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Counter.h"

@implementation Counter

-(void) addTally
{
    self.countForTally++; // add extra tally mark
}

-(void) decreaseTally
{
    if (self.countForTally>0) self.countForTally--; // remove a tally mark
}

-(void) resetTally
{
    self.countForTally = 0; // reset tally marks
}

@end
