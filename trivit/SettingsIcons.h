//
//  SettingsIcons.h
//  Trivit
//
//  Created by Pieterjan Criel - Wouter Devriendt on 30/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface SettingsIcons : NSObject

// iOS Controls Customization Outlets
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *feedback2Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *resetTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *trashTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *tutorialsTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *feedback1Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *vibrateTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray *color9Targets;

// Drawing Methods
+ (void)drawFeedback2;

+ (void)drawReset;

+ (void)drawTrash;

+ (void)drawTutorials;

+ (void)drawFeedback1;

+ (void)drawVibrate;

+ (void)drawColor9;

// Generated Images
+ (UIImage *)imageOfFeedback2;

+ (UIImage *)imageOfReset;

+ (UIImage *)imageOfTrash;

+ (UIImage *)imageOfTutorial;

+ (UIImage *)imageOfFeedback;

+ (UIImage *)imageOfVibrate;

+ (UIImage *)imageOfColor;

@end
