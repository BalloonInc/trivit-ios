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
@property (nonatomic) NSUInteger numberOfPages;
@end

@implementation TutMasterViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    //set number of pages in the tutorial
    self.numberOfPages=4;
    
    self.mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self.dataSource=self;
    [[self view] setFrame:[[self view] bounds]];
    
    TutChildViewController *initialViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (TutChildViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    TutChildViewController *childViewController = (TutChildViewController *)[self.mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialChildViewController"];
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
    if (index == self.numberOfPages)
        return nil;
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return self.numberOfPages;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}

// For the tutorial, only allow portrait mode
-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

//Function to make the bottom bar transparent
-(void)viewDidLayoutSubviews {
    
    if( [self.view.subviews count] == 2 ) {
        UIScrollView* scrollView = nil;
        UIPageControl* pageControl = nil;
        for( UIView* subView in self.view.subviews ) {
            if( [subView isKindOfClass:[UIScrollView class]])
                scrollView = (UIScrollView*)subView;
            else if( [subView isKindOfClass:[UIPageControl class]] )
                pageControl = (UIPageControl*)subView;
                
            if( scrollView != nil && pageControl != nil ) {
                // expand scroll view to fit entire view
                scrollView.frame = self.view.bounds;
                // put page control in front
                [self.view bringSubviewToFront:pageControl];
            }
        }
        [super viewDidLayoutSubviews];
    }
}
@end
