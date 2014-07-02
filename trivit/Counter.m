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
    self.counter++; // add extra tally mark
}

-(void) decreaseTally
{
    if (self.counter>0) self.counter--; // remove a tally mark
}

-(void) resetTally
{
    self.counter = 0; // reset tally marks
}

@end
