//
//  settingsViewController.m
//  trivit
//
//  Created by Wouter on 26/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "TallyModel.h"
#import "SettingButtonCell.h"
#import <AudioToolbox/AudioToolbox.h>
#import "Colors.h"

@interface SettingsViewController () <UIAlertViewDelegate>
@property (strong, nonatomic, readonly) NSString *sureToDeleteTitle;
@property (strong,nonatomic, readonly) NSString *sureToResetTitle;

@end

@implementation SettingsViewController

#pragma mark - Constants
int const REMOVECELL = 0;
int const COLORCELL = 1;
int const TUTORIALCELL = 2;
int const RESETCELL = 3;
int const HELPCELL = 4;
int const VIBRATIONCELL = 5;
int const NUMBEROFCELLS = 6;

#pragma mark - Lazy instantiators

-(NSString*) sureToDeleteTitle{
    return NSLocalizedString(@"Delete all Trivits",@"Message box title");
}

-(NSString*) sureToResetTitle{
    return NSLocalizedString(@"Reset all Trivits", @"Message box title");
}

- (NSString *) vibrationString:(BOOL)on{
    NSString *yesOrNo = on?NSLocalizedString(@"On", @"Setting: on"):NSLocalizedString(@"Off", @"Setting: off");
    ;
    return [NSString stringWithFormat:NSLocalizedString(@"Vibration - %@", @"label for vibration setting"),yesOrNo];
}

- (NSString *) colorStringforIndex:(int)index{
    NSString *color = [[Colors colorSetNames] objectAtIndex:index];
    ;
    return [NSString stringWithFormat:NSLocalizedString(@"Color - %@", @"label for vibration setting"),color];
}

-(void) viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithBool:self.appSettings.vibrationFeedback] forKey:@"vibrationFeedback"];
    [defaults setObject:[NSNumber numberWithInteger:self.appSettings.selectedColorSet] forKey:@"selectedColorSet"];
    
    [defaults synchronize];
}
- (IBAction)toggleColorSet:(id)sender
{
    self.appSettings.selectedColorSet=(self.appSettings.selectedColorSet+1)%[[Colors colorSetNames] count];
    
    [self updateBackgroundColor];
    [self.collectionView reloadData];
}

-(void) updateBackgroundColor
{
    self.collectionView.backgroundColor = [Colors colorWithIndex:0 usingColorSet:[Colors colorsetWithIndex:2*self.appSettings.selectedColorSet]];
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    [self updateBackgroundColor];
}

- (IBAction)vibrationButtonPressed:(id)sender {
    self.appSettings.vibrationFeedback = !self.appSettings.vibrationFeedback;
    if(self.appSettings.vibrationFeedback){
        NSMutableArray* arr = [NSMutableArray arrayWithObjects:
                               [NSNumber numberWithBool:YES],
                               [NSNumber numberWithInt:500], nil];
        
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              arr,@"VibePattern",
                              [NSNumber numberWithFloat:1.],@"Intensity",nil];
        
        //declare function before usage
        int AudioServicesPlaySystemSoundWithVibration();
        
        AudioServicesPlaySystemSoundWithVibration(4095,nil,dict);
        
    }

    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:VIBRATIONCELL inSection:0]]];
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TallyModel"];
        [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError *error;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if([alertView.title isEqualToString:self.sureToDeleteTitle]){
            for (NSManagedObject *record in fetchedObjects)
                [self.managedObjectContext deleteObject:record];
        }
        if([alertView.title isEqualToString:self.sureToResetTitle])
            for (TallyModel *record in fetchedObjects)
                record.counter = [NSNumber numberWithInteger:0];

        error = nil;
        [self.managedObjectContext save:&error];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return NUMBEROFCELLS;
}

 
- (SettingButtonCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SettingButtonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"cell_%d",indexPath.item+1] forIndexPath:indexPath];
    
    // Configure the cell

    cell.backgroundColor = [Colors colorWithIndex:0 usingColorSet:[Colors colorsetWithIndex:2*self.appSettings.selectedColorSet+1]];

    
    if(indexPath.item ==COLORCELL)
        cell.buttonText = [self colorStringforIndex:self.appSettings.selectedColorSet];
    
    if (indexPath.item==VIBRATIONCELL)
        cell.buttonText = [self vibrationString:self.appSettings.vibrationFeedback];
    
    
    return cell;
}



@end
