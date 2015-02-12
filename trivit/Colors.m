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

+ (NSArray *)colorsetWithIndex:(NSInteger)index {
    NSArray *colorSetArray;

    switch (index) {
        case 0:
            colorSetArray = [Colors flatDesignColorsLight];
            break;
        case 1:
            colorSetArray = [Colors flatDesignColorsDark];
            break;
        case 2:
            colorSetArray = [Colors trivitColorsLight];
            break;
        case 3:
            colorSetArray = [Colors trivitColorsDark];
            break;
        case 4:
            colorSetArray = [Colors pinkishColorsLight];
            break;
        case 5:
            colorSetArray = [Colors pinkishColorsDark];
            break;
        case 6:
            colorSetArray = [Colors blueColorsLight];
            break;
        case 7:
            colorSetArray = [Colors blueColorsDark];
            break;
        case 8:
            colorSetArray = [Colors mSeriesColorsLight];
            break;
        case 9:
            colorSetArray = [Colors mSeriesColorsDark];
            break;
        case 10:
            colorSetArray = [Colors jSeriesColorsLight];
            break;
        case 11:
            colorSetArray = [Colors jSeriesColorsDark];
            break;
        default:
            colorSetArray = [Colors flatDesignColorsLight];
    }
    return colorSetArray;
}

+ (NSArray *)flatDesignColorsLight {
    return @[
            @"1ABC9C", // Turquoise
            @"2ECC71", // Emerald
            @"3498DB", // Petermann River
            @"F1C40F", // Sun Flower
            @"E67E22", // Carrot
            @"E74C3C"  // Alizarin
    ];
}

+ (NSArray *)flatDesignColorsDark {
    return @[
            @"16A085", // Green Sea
            @"27AE60", // Nephritis
            @"2980B9", // Belize Hole
            @"F39C12", // Orange
            @"D35400", // Pumpkin
            @"C0392B"  // Pomegranate
    ];
}

+ (NSArray *)trivitColorsLight {
    return @[
            @"88E8D9", // AppleBlueSeaGreen
            @"FFB736", // Orangish
            @"FF7075", // Non-flashing Pink
            @"54D3FF", // Gay Blue
            @"43D487"  // Green
    ];
}

+ (NSArray *)trivitColorsDark {
    return @[
            @"77CBBE", // AppleBlueSeaGreen
            @"FBAB1B", // Orangish
            @"F05F64", // Non-flashing Pink
            @"45C5F2", // Gay Blue
            @"3AB775"  // Green
    ];
}

+ (NSArray *)pinkishColorsLight {
    return @[
            @"EF2D72",
            @"A6122E",
            @"75081D",
            @"A6122E",
            @"EF2D72",
            @"F05FA2",
            @"F1D4C3"
    ];
}

+ (NSArray *)pinkishColorsDark {
    return @[
            @"D42865",
            @"8A0F26",
            @"580616",
            @"8A0F26",
            @"D42865",
            @"D4548F",
            @"D6BCAD"
    ];
}

+ (NSArray *)blueColorsLight {
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

+ (NSArray *)blueColorsDark {
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

+ (NSArray *)mSeriesColorsLight {
    return @[
             @"E8C614", // Mieke
             @"28BBCC", // Mieke
             @"AC149A", // Mieke
             @"E83871", // Mieke
             ];
}

+ (NSArray *)mSeriesColorsDark {
    return @[
             @"97810D", // Mieke
             @"1A7984", // Mieke
             @"700D64", // Mieke
             @"97244F", // Mieke
             ];
}

+ (NSArray *)jSeriesColorsLight {
    return @[
             @"E616AD", // Jolien
             @"15CFBD", // Jolien
             @"FE113A", // Jolien
             @"4BED04", // Jolien
             ];
}

+ (NSArray *)jSeriesColorsDark {
    return @[
             @"950E70", // Jolien
             @"0D867A", // Jolien
             @"A50B26", // Jolien
             @"309903", // Jolien
             ];
}

+ (NSArray *)colorSetNames {
    return @[
            NSLocalizedString(@"Default", @"Color set name"),
            NSLocalizedString(@"Trivit", @"Color set name"),
            NSLocalizedString(@"Pink", @"Color set name"),
            NSLocalizedString(@"Blue",@"Color set name"),
            NSLocalizedString(@"M",@"Color set name"),
            NSLocalizedString(@"J",@"Color set name"),
            NSLocalizedString(@"Red",@"Color set name"),
            NSLocalizedString(@"Green",@"Color set name")
    ];
}

+ (UIColor *)colorWithHexString:(NSString *)hex {
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString length] != 6) return [UIColor grayColor];

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

+ (UIColor *)randomColor {
    return [self randomColorUsingColorSet:nil];
}

+ (UIColor *)colorWithIndex:(NSInteger)index {
    return [self colorWithIndex:index usingColorSet:nil];
}

+ (UIColor *)randomColorUsingColorSet:(NSArray *)colorSet {
    return [self colorWithIndex:(NSInteger) arc4random() usingColorSet:colorSet];
}

+ (UIColor *)colorWithIndex:(NSInteger)index usingColorSet:(NSArray *)colorSet {
    //By Default, use iOSColors
    if (!colorSet)
        colorSet = [self flatDesignColorsLight];

    index = (int) index % [colorSet count];
    NSString *hexColorString = colorSet[index];
    return [self colorWithHexString:hexColorString];
}

@end
