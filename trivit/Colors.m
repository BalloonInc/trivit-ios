//
//  Colors.m
//  trivit
//
//  Created by Wouter on 24/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Colors.h"

@implementation Colors

+(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
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


+(UIColor *) randomColor{
      switch (arc4random() % 8){
//        case 0: return [self colorWithHexString:@"77CBBE"];
//        case 1: return [self colorWithHexString:@"FBAB1B"];
//        case 2: return [self colorWithHexString:@"F05F64"];
//        case 3: return [self colorWithHexString:@"45C5F2"];
//        case 4: return [self colorWithHexString:@"
        // IOS8 colors (taken from some screenshots)
        case 0: return [self colorWithHexString:@"E0272E"]; // Red
        case 1: return [self colorWithHexString:@"459E20"]; // Green
        case 2: return [self colorWithHexString:@"3D96BE"]; // Blue
        case 3: return [self colorWithHexString:@"EI2A64"]; // Heavy pink
        case 4: return [self colorWithHexString:@"E65F2E"]; // Orange
        case 5: return [self colorWithHexString:@"A22CBE"]; // Purple
        case 6: return [self colorWithHexString:@"201DC2"]; // Dark blue
        case 7: return [self colorWithHexString:@"261897"]; // Very dark blue
    }
    // should not happen
    return [UIColor blackColor];
}

@end
