//
//  tutorialContainerViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 10/01/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "TutContainerViewController.h"
#import "TutMasterViewController.h"

@interface TutContainerViewController ()
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (strong, nonatomic) TutMasterViewController* tutMasterVC;
@end
@implementation TutContainerViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[TutMasterViewController class]]){
        self.tutMasterVC = (TutMasterViewController *) segue.destinationViewController;
        self.tutMasterVC.skipButton=self.skipButton; // set reference to self in tutmasterVC
    }
}
- (IBAction)skipTutorialButtonPressed:(id)sender {
    if(self.tutMasterVC)
        [self.tutMasterVC dismissTutorial];
}

@end
