//
//  Colors.h
//  trivit
//
//  Created by Wouter on 24/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface Colors : NSObject

// predefined colorsets
+(NSArray*) greenColorsLight;
+(NSArray*) greenColorsDark;
+(NSArray*) redColorsLight;
+(NSArray*) redColorsDark;
+(NSArray*) blueColorsLight;
+(NSArray*) blueColorsDark;
+(NSArray*) trivitColorsLight;
+(NSArray*) trivitColorsDark;
+(NSArray*) flatDesignColorsLight;
+(NSArray*) flatDesignColorsDark;

+(NSArray*) colorSetNames;

//takes as input a hex formatted color and returns UIColor
+(UIColor*) colorWithHexString:(NSString*)hex;
//returns random color using default colorset;
+(UIColor*) randomColor;
//returns color with certain index using default colorset
+(UIColor*) colorWithIndex:(NSInteger)index;
//returns random color from a certain colorset
+(UIColor*) randomColorUsingColorSet:(NSArray*)colorSet;
//returns a color with certain index with certain colorset
+(UIColor*) colorWithIndex:(NSInteger)index
             usingColorSet:(NSArray*)colorSet;
//returns a colorset, based on an index
//TODO: make a dictionary instead, so we can return based on name
+(NSArray*) colorsetWithIndex:(NSInteger)index;
@end
