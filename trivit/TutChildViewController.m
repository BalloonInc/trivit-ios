//
//  TutChildViewController.m
//  trivit
//
//  Created by Wouter on 27/10/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TutChildViewController.h"
#import "TutMasterViewController.h"
@interface TutChildViewController ()
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIImageView *tutorialImage;

@end

@implementation TutChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tutorialImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"tut_page_%lu",(unsigned long)self.index]];
    [self.tutorialImage setContentMode:UIViewContentModeScaleAspectFit];
    self.view.backgroundColor = [UIColor colorWithRed:48./256 green:108./256 blue:87./256 alpha:1];

    switch (self.index) {
        case 0:
            self.tutorialText = NSLocalizedString(@"Tap the pen to add a new Trivit", @"tutorial");
            break;
        case 1:
            self.tutorialText = NSLocalizedString(@"Give your Trivit a name", @"tutorial");
            break;
        case 2:
            self.tutorialText = NSLocalizedString(@"Open or close your new Trivit with a single tap", @"tutorial");
            break;
        case 3:
            self.tutorialText = NSLocalizedString(@"Tap to increase the count", @"tutorial");
            break;
        case 4:
            self.tutorialText = NSLocalizedString(@"Tap the minus to decrease the count, hold long to reset", @"tutorial");
            break;
        case 5:
            self.tutorialText = @"";
            // last page: show done button
            self.getStartedButton.hidden = false;
            break;
        default:
            self.tutorialText = @"Oops, that went wrong!";
            break;
    }
    self.textLabel.text = self.tutorialText;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired=1;
    [self.view addGestureRecognizer:tap];

}

-(void) handleTap:(UIGestureRecognizer*) tapRecognizer{
    [self.masterVC pageFoward:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
