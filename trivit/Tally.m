//
//  Counter.m
//  trivit
//
//  Created by Wouter Devriendt on 25/06/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Tally.h"

@implementation Tally

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

-(float) cellHeigthWithFrameWidth: (float) width andSectionHeight: (float) sectionHeight // values are based on trial and error
{
    float tallyCount = ceil((self.counter / 5.));
    float divisor = width / 34.;
    int rows = ceil(tallyCount/divisor);
    return sectionHeight + rows*34;
}

@end
