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

@end

@implementation TutChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textLabel.text = self.tutorialText;
    // if last page, show done button, ontherwise hide it
    if (self.index !=2){
        self.getStartedButton.hidden=true;
    }
    // Do any additional setup after loading the view.
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
