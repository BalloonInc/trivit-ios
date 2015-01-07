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
            colorSetArray = [Colors greenColorsLight];
            break;
        case 3:
            colorSetArray = [Colors greenColorsDark];
            break;
        case 4:
            colorSetArray = [Colors blueColorsLight];
            break;
        case 5:
            colorSetArray = [Colors blueColorsDark];
            break;
        case 6:
            colorSetArray = [Colors redColorsLight];
            break;
        case 7:
            colorSetArray = [Colors redColorsDark];
            break;
        case 8:
            colorSetArray = [Colors trivitColorsLight];
            break;
        case 9:
            colorSetArray = [Colors trivitColorsDark];
            break;
        default:
            colorSetArray = [Colors greenColorsLight];
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

+(NSArray *)greenColorsLight
{
    return @[
             @"57A30D", // Green
             @"63A912", // Green
             @"6FB016", // Green
             @"7DB51C", // Green
             @"87BD21", // Green
             @"94C325", // Green
             @"A1CB2B", // Green
             @"ADCF30"  // Green
             ];
}

+(NSArray *)greenColorsDark
{
    return @[
             @"3B891F", // Blue
             @"448E24", // Blue
             @"4E9529", // Blue
             @"59992E", // Blue
             @"61A133", // Blue
             @"6BA637", // Blue
             @"76AE3E", // Blue
             @"80B242"  // Blue
             ];
}

+(NSArray *)blueColorsLight
{
    return @[
             @"0693FB", // Blue
             @"109EFB", // Blue
             @"1AA9FB", // Blue
             @"21B4FB", // Blue
             @"28BEFC", // Blue
             @"2EC6FA", // Blue
             @"36CFFA", // Blue
             ];
}

+(NSArray *)blueColorsDark
{
    return @[
             @"245FD2", // Green
             @"2668D9", // Green
             @"2E73DA", // Green
             @"347EDB", // Green
             @"3A87DD", // Green
             @"3F8FDC", // Green
             @"4689DD", // Green
             ];
}

+(NSArray *)redColorsLight
{
    return @[
             @"8A0017", // Red
             @"A2001B", // Red
             @"B6001D", // Red
             @"C90025", // Red
             @"E20026", // Red
             @"F7002A", // Red
             @"FF0026", // Red
             ];
}

+(NSArray *)redColorsDark
{
    return @[
             @"5F011A", // Red
             @"6D0420", // Red
             @"7C0725", // Red
             @"8A0C2B", // Red
             @"9B0F30", // Red
             @"AB1436", // Red
             @"B91736", // Red
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

+(NSArray *)colorSetNames
{
    return @[
             @"Default",
             @"Green",
             @"Blue",
             @"Red",
             @"Trivit"
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
        colorSet = [self greenColorsLight];
    
    index = (int)index % [colorSet count];
    NSString* hexColorString = colorSet[index];
    return [self colorWithHexString:hexColorString];
}

@end
