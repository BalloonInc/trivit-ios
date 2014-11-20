//
//  InterfaceController.m
//  trivit WatchKit Extension
//
//  Created by Wouter on 20/11/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "InterfaceController.h"
#import "WKTableVIewRowController.h"
//#import "Colors.h"

@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;

@end


@implementation InterfaceController
#pragma mark - Initialization

- (instancetype)initWithContext:(id)context {
    self = [super initWithContext:context];
    
    if (self) {
        //NSAssert([context isKindOfClass:[AAPLListInfo class]], @"Expected class of `context` is AAPLListInfo.");
        
        //AAPLListInfo *listInfo = context;
        //_listDocument = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL];
        
        [self setTitle:NSLocalizedString(@"Trivit", @"Trivit title for Watch app")];
        [self loadTableData];
    }
    
    return self;
}

- (void)loadTableData {
    [self.interfaceTable setNumberOfRows:2 withRowType:@"TrivitWKCel"];
    [self configureRowControllerAtIndex:0];
    [self configureRowControllerAtIndex:1];
    
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    NSLog(@"%@ did deactivate", self);
}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    [listItemRowController setCounter:5+6*index];
    [listItemRowController setBackgroundColorButton:[self colorWithIndex:index usingColorSet:[self flatDesignColorsDark]]];
    [listItemRowController setBackgroundColorCell:[self colorWithIndex:index usingColorSet:[self flatDesignColorsLight]]];

    [listItemRowController setItemName:index==0?@"Days in jail":@"Drinks"];
    
}
#pragma mark - TEMP color stuff

// All colors are defined below
// To add a color, add a *Light and *Dark array and add them in the colorsetWithIndex function below
// they should be
//      case 2n   --> light version
//      case 2n+1 --> dark version

-(NSArray*) colorsetWithIndex:(NSInteger)index
{
    NSArray *colorSetArray;
    
    switch (index) {
        case 0:
            colorSetArray = [self flatDesignColorsLight];
            break;
        case 1:
            colorSetArray = [self flatDesignColorsDark];
            break;
        default:
            colorSetArray = [self flatDesignColorsLight];
    }
    return colorSetArray;
}

-(NSArray *)flatDesignColorsLight
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

-(NSArray *)flatDesignColorsDark
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


-(UIColor*)colorWithHexString:(NSString*)hex
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

-(UIColor*) randomColor
{
    return [self randomColorUsingColorSet:nil];
}

-(UIColor*) colorWithIndex:(NSInteger)index
{
    return [self colorWithIndex:index usingColorSet:nil];
}

-(UIColor *) randomColorUsingColorSet: (NSArray *)colorSet
{
    return [self colorWithIndex:(NSInteger)arc4random() usingColorSet:colorSet];
}

-(UIColor *) colorWithIndex:(NSInteger)index usingColorSet: (NSArray *)colorSet
{
    //By Default, use iOSColors
    if (!colorSet)
        colorSet = [self flatDesignColorsLight];
    
    index = (int)index % [colorSet count];
    NSString* hexColorString = colorSet[index];
    return [self colorWithHexString:hexColorString];
}

@end


