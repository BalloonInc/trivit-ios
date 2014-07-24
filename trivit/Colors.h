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

+(UIColor*) colorWithHexString:(NSString*)hex;
+(UIColor*) randomColor;

@end
