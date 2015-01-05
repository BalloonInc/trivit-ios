//
//  TutMasterViewController.h
//  trivit
//
//  Created by Wouter on 27/10/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TutChildViewController.h"

@interface TutMasterViewController : UIPageViewController <UIPageViewControllerDataSource>

-(void)pageFoward:(TutChildViewController*)previousViewController;
@end
