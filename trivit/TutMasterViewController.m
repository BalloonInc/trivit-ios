//
//  TutMasterViewController.m
//  trivit
//
//  Created by Wouter on 27/10/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TutMasterViewController.h"
#import "TutChildViewController.h"

@interface TutMasterViewController ()
@property (strong,nonatomic) UIStoryboard *mainStoryboard;
@end

@implementation TutMasterViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];

    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    TutChildViewController *initialViewController = [self viewControllerAtIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (TutChildViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    TutChildViewController *childViewController = (TutChildViewController *)[self.mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialChildViewController"];
        
    switch (index) {
        case 0:
            childViewController.tutorialText = @"This will be a tutorial";
            break;
        case 1:
            childViewController.tutorialText = @"We scroll through some images";
            break;
        case 2:
            childViewController.tutorialText = @"And now it is done";
            break;
        default:
            childViewController.tutorialText = @"oops, that went wrong!";
            break;
    }
    childViewController.index=index;
    return childViewController;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(TutChildViewController *)viewController index];
    
    if (index == 0)
        return nil;
    
    // Decrease the index by 1 to return
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(TutChildViewController *)viewController index];
    
    index++;
    
    if (index == 3)
        return nil;
    
    return [self viewControllerAtIndex:index];
    
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return 3;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}


@end
