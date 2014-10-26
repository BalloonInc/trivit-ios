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

@end

@implementation settingsViewController

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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete all Trivits" message:@"Are you sure you want to delete all trivits?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
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
        for (NSManagedObject *object in fetchedObjects)
        {
            [self.managedObjectContext deleteObject:object];
        }
        
        error = nil;
        [self.managedObjectContext save:&error];
        
    }
    
}


- (void)vibrationChanged:(id)sender {
    self.appSettings.vibrationFeedback = self.vibrationSwitch.isOn;
}

@end
