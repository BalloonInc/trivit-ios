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
@property (strong, nonatomic, readonly) NSString *sureToDeleteTitle;
@property (strong,nonatomic, readonly) NSString *sureToResetTitle;
@end

@implementation settingsViewController

#pragma mark - Lazy instantiators

-(NSString*) sureToDeleteTitle{
    return @"Delete all Trivits";
}
-(NSString*) sureToResetTitle{
    return @"Reset all Trivits";
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


- (IBAction)deleteAllTrivits:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.sureToDeleteTitle message:@"Are you sure you want to delete all trivits?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];

}
- (IBAction)resetAllTrivits:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.sureToResetTitle message:@"Are you sure you want to reset all counts to 0?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];

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

@end
