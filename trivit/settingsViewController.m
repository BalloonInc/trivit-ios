//
//  settingsViewController.m
//  trivit
//
//  Created by Wouter on 26/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "settingsViewController.h"

@interface settingsViewController ()
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
    self.colorPicker.selectedSegmentIndex = self.appSettings.colorSet;
    self.vibrationSwitch.on = self.appSettings.vibrate;
    
    [super viewWillAppear:animated];
    [self.colorPicker addTarget:self
                         action:@selector(updateColorSet:)
               forControlEvents:UIControlEventValueChanged];
    [self.vibrationSwitch addTarget:self
                         action:@selector(vibrationChanged:)
               forControlEvents:UIControlEventValueChanged];
}


- (void)updateColorSet:(id)sender
{
    self.appSettings.colorSet=self.colorPicker.selectedSegmentIndex;
}


- (IBAction)deleteAllTrivits:(id)sender {
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


- (void)vibrationChanged:(id)sender {
    self.appSettings.vibrate = self.vibrationSwitch.isOn;
}

@end
