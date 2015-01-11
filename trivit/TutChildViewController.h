//
//  TutorialPageChildViewController.h
//  trivit
//
//  Created by Wouter on 27/10/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TutMasterViewController;

@interface TutChildViewController : UIViewController

@property(strong, nonatomic) NSString *tutorialText;
@property(nonatomic) NSUInteger index;
@property(strong, nonatomic) TutMasterViewController *masterVC;
@property(strong, nonatomic) UIButton *skipButton;
@end
