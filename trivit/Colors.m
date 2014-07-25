//
//  Colors.m
//  trivit
//
//  Created by Wouter on 24/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Colors.h"

@implementation Colors

+(NSArray *)iOSColors
{
      return @[
          @"E0272E", // Red
		  @"459E20", // Green
		  @"3D96BE", // Blue
		  @"EI2A64", // Heavy pink
		  @"E65F2E", // Orange
		  @"A22CBE", // Purple
          @"201DC2", // Dark blue
		  @"261897" // Very dark blue
		  ];
}

+(NSArray *)trivitColors
{
        return @[
          @"77CBBE", // AppleBlueSeaGreen
          @"FBAB1B", // Orangish
          @"F05F64", // Non-flashing Pink
          @"45C5F2", // Gay Blue
          @"3AB775", // Green
          ];
}

+(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}

+(UIColor*) randomColor
{
    return [self randomColorUsingColorSet:nil];
}

+(UIColor*) colorWithIndex:(int)index
{
    return [self colorWithIndex:index usingColorSet:nil];
}

+(UIColor *) randomColorUsingColorSet: (NSArray *)colorSet
{
    return [self colorWithIndex:(int)arc4random() usingColorSet:colorSet];
}

+(UIColor *) colorWithIndex:(int)index usingColorSet: (NSArray *)colorSet
{
    //By Default, use iOSColors
    if (!colorSet)
        colorSet = [self iOSColors];
    
    index = (int)index % [colorSet count];
    NSString* hexColorString = colorSet[index];
    return [self colorWithHexString:hexColorString];
}

@end
