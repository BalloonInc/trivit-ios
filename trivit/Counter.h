//
//  Counter.h
//  trivit
//
//  Created by Wouter Devriendt on 25/06/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Counter : NSObject

@property (nonatomic, strong) NSString* title;
@property (nonatomic) NSInteger counter;

-(void) addTally;

@end
