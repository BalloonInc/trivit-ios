//
//  settingsViewController.m
//  trivit
//
//  Created by Wouter on 26/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "settingsViewController.h"

@interface settingsViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *colorPicker;
@property (weak, nonatomic) IBOutlet UISwitch *vibrationSwitch;
@property (weak, nonatomic) IBOutlet UIButton *invisibleSwitchButton;
@property (strong, nonatomic, readonly) NSString *sureToDeleteTitle;
@property (strong,nonatomic, readonly) NSString *sureToResetTitle;
@end

@implementation settingsViewController

#pragma mark - Lazy instantiators

-(NSString*) sureToDeleteTitle{
    return NSLocalizedString(@"Delete all Trivits",@"Message box title");
}

-(NSString*) sureToResetTitle{
    return NSLocalizedString(@"Reset all Trivits", @"Message box title");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    self.colorPicker.selectedSegmentIndex = self.appSettings.selectedColorSet;
    self.vibrationSwitch.on = self.appSettings.vibrationFeedback;
    
    [super viewWillAppear:animated];
    [self.colorPicker addTarget:self
                         action:@selector(updateColorSet:)
               forControlEvents:UIControlEventValueChanged];
    [self.vibrationSwitch addTarget:self
                         action:@selector(vibrationChanged:)
               forControlEvents:UIControlEventValueChanged];
}

-(void) viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithBool:self.vibrationSwitch.isOn] forKey:@"vibrationFeedback"];
    [defaults setObject:[NSNumber numberWithInteger:self.colorPicker.selectedSegmentIndex] forKey:@"selectedColorSet"];
    
    [defaults synchronize];
}


- (void)updateColorSet:(id)sender
{
    self.appSettings.selectedColorSet=self.colorPicker.selectedSegmentIndex;
}

- (IBAction)invisibleSwitchButtonPressed:(id)sender {
    bool newState = !self.vibrationSwitch.isOn;
    [self.vibrationSwitch setOn:newState animated:YES];
    self.appSettings.vibrationFeedback = newState;
}

- (IBAction)deleteAllTrivits:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.sureToDeleteTitle
                                                    message:NSLocalizedString(@"Are you sure you want to delete all trivits?",@"Message box content")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No",@"")
                                          otherButtonTitles:NSLocalizedString(@"Yes",@""), nil];
    [alert show];

}
- (IBAction)resetAllTrivits:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.sureToResetTitle
                                                    message:NSLocalizedString(@"Are you sure you want to reset all counts to 0?", @"Message box content")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No",@"")
                                          otherButtonTitles:NSLocalizedString(@"Yes",@""), nil];
    [alert show];

}

- (IBAction)showTutorial:(id)sender {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *tutorialVC = (UINavigationController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialMasterViewController"];
    [self presentViewController:tutorialVC animated:YES completion:^{}];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Tally"];
        [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError *error;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if([alertView.title isEqualToString:self.sureToDeleteTitle]){
            for (NSManagedObject *record in fetchedObjects)
                [self.managedObjectContext deleteObject:record];
        }
        if([alertView.title isEqualToString:self.sureToResetTitle]){
            for (NSManagedObject *record in fetchedObjects)
                [record setValue: [NSNumber numberWithInteger:0] forKey:@"counter"];
        }
        error = nil;
        [self.managedObjectContext save:&error];
    }
}

- (void)vibrationChanged:(id)sender {
    self.appSettings.vibrationFeedback = self.vibrationSwitch.isOn;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}
@end
