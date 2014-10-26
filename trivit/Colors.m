//
//  Colors.m
//  trivit
//
//  Created by Wouter on 24/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Colors.h"

@implementation Colors

// All colors are defined below
// To add a color, add a *Light and *Dark array and add them in the colorsetWithIndex function below
// they should be
//      case 2n   --> light version
//      case 2n+1 --> dark version

+(NSArray*) colorsetWithIndex:(NSInteger)index
{
    NSArray *colorSetArray;
    
    switch (index) {
        case 0:
            colorSetArray = [Colors flatDesignColorsLight];
            break;
        case 1:
            colorSetArray = [Colors flatDesignColorsDark];
            break;
        case 2:
            colorSetArray = [Colors iOSColorsLight];
            break;
        case 3:
            colorSetArray = [Colors iOSColorsDark];
            break;
        case 4:
            colorSetArray = [Colors trivitColorsLight];
            break;
        case 5:
            colorSetArray = [Colors trivitColorsDark];
            break;
        default:
            colorSetArray = [Colors iOSColorsLight];
    }
    return colorSetArray;
}

+(NSArray *)flatDesignColorsLight
{
        return @[
          @"1ABC9C", // Turquoise
          @"2ECC71", // Emerald
          @"3498DB", // Petermann River
          @"F1C40F", // Sun Flower
          @"E67E22", // Carrot
          @"E74C3C"  // Alizarin
          ];
}

+(NSArray *)flatDesignColorsDark
{
        return @[
          @"16A085", // Green Sea
          @"27AE60", // Nephritis
          @"2980B9", // Belize Hole
          @"F39C12", // Orange
          @"D35400", // Pumpkin
          @"C0392B"  // Pomegranate
          ];
}

+(NSArray *)iOSColorsLight
{
    return @[
             @"FC2C34", // Red
             @"51BA26", // Green
             @"46ADDB", // Blue
             @"FC2F70", // Heavy pink
             @"FF6933", // Orange
             @"BB33DB", // Purple
             //@"2521DE", // Dark blue
             @"2D1CB3"  // Very dark blue
             ];
}

+(NSArray *)iOSColorsDark
{
    return @[
             @"E0272E", // Red
             @"459E20", // Green
             @"3D96BE", // Blue
             @"E12A64", // Heavy pink
             @"E65F2E", // Orange
             @"A22CBE", // Purple
             //@"201DC2", // Dark blue
             @"221587"  // Very dark blue
             ];
}

+(NSArray *)trivitColorsLight
{
    return @[
             @"88E8D9", // AppleBlueSeaGreen
             @"FFB736", // Orangish
             @"FF7075", // Non-flashing Pink
             @"54D3FF", // Gay Blue
             @"43D487"  // Green
             ];
}

+(NSArray *)trivitColorsDark
{
    return @[
             @"77CBBE", // AppleBlueSeaGreen
             @"FBAB1B", // Orangish
             @"F05F64", // Non-flashing Pink
             @"45C5F2", // Gay Blue
             @"3AB775"  // Green
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

+(UIColor*) colorWithIndex:(NSInteger)index
{
    return [self colorWithIndex:index usingColorSet:nil];
}

+(UIColor *) randomColorUsingColorSet: (NSArray *)colorSet
{
    return [self colorWithIndex:(NSInteger)arc4random() usingColorSet:colorSet];
}

+(UIColor *) colorWithIndex:(NSInteger)index usingColorSet: (NSArray *)colorSet
{
    //By Default, use iOSColors
    if (!colorSet)
        colorSet = [self iOSColorsLight];
    
    index = (int)index % [colorSet count];
    NSString* hexColorString = colorSet[index];
    return [self colorWithHexString:hexColorString];
}

@end
