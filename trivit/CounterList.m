//
//  CounterList.m
//  trivit
//
//  Created by Wouter Devriendt on 25/06/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "CounterList.h"
#import "Counter.h"

@interface CounterList()
@property (strong,nonatomic) NSMutableArray *tallies;

@end

@implementation CounterList

- (NSMutableArray *) tallies
{
    if (!_tallies)
        _tallies = [[NSMutableArray alloc] init];
    return _tallies;
}

- (void)addCounter:(Counter *)counter
{
        [self.tallies addObject:counter];
}


@end
