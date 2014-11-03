//
//  TutChildViewController.m
//  trivit
//
//  Created by Wouter on 27/10/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TutChildViewController.h"

@interface TutChildViewController ()
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIImageView *tutorialImage;

@end

@implementation TutChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tutorialImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"tut_page_%lu",(unsigned long)self.index]];
    
    switch (self.index) {
        case 0:
            self.tutorialText = NSLocalizedString(@"Tap to add tallies", @"tutorial");
            break;
        case 1:
            self.tutorialText = NSLocalizedString(@"Tap and hold to edit title", @"tutorial");
            break;
        case 2:
            self.tutorialText = NSLocalizedString(@"Swipe left to remove", @"tutorial");
            break;
        case 3:
            self.tutorialText = @"";
            // last page: show done button
            self.getStartedButton.hidden = false;
            self.getStartedButton.titleLabel.text = NSLocalizedString(@"Get started!", @"Get started button");
            break;
        default:
            self.tutorialText = NSLocalizedString(@"oops, that went wrong!", @"tutorial error");
            break;
    }
    self.textLabel.text = self.tutorialText;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)getStartedButtonPressed:(id)sender {
    //dismiss, on completion set boolean tutorialShown to 0 so it is not shown anymore next time
    [self dismissViewControllerAnimated:YES completion:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithBool:true] forKey:@"tutorialShown"];
}];
}

@end
