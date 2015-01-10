//
//  TutMasterViewController.h
//  trivit
//
//  Created by Wouter on 27/10/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TutChildViewController.h"
#import "TutContainerViewController.h"

@interface TutMasterViewController : UIPageViewController <UIPageViewControllerDataSource>
@property (strong,nonatomic) UIButton* skipButton;
-(void)pageFoward:(TutChildViewController*)previousViewController;
-(void) dismissTutorial;

@end
