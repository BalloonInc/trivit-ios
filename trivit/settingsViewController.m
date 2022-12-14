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
#import "Colors.h"
#import "FeedbackViewController.h"
#import "SettingsIcons.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Google/Analytics.h>

@interface SettingsViewController () <UIAlertViewDelegate>
@property(strong, nonatomic, readonly) NSString *sureToDeleteTitle;
@property(strong, nonatomic, readonly) NSString *sureToResetTitle;
@property(nonatomic) int cellHeight;
@property(nonatomic) int cellWidth;
@property(nonatomic) int spacing;
@property(strong,nonatomic) id<GAITracker> tracker;
@end

@implementation SettingsViewController

#pragma mark - Constants
int const TRASHCELL = 0;
int const COLORCELL = 1;
int const TUTORIALCELL = 2;
int const RESETCELL = 3;
int const FEEDBACKCELL = 4;
int const VIBRATIONCELL = 5;
int const NUMBEROFCELLS = 6;

#pragma mark - Lazy instantiators

- (NSString *)sureToDeleteTitle {
    return NSLocalizedString(@"Delete all Trivits", @"Message box title");
}

- (NSString *)sureToResetTitle {
    return NSLocalizedString(@"Reset all Trivits", @"Message box title");
}

- (NSString *)vibrationString:(BOOL)on {
    NSString *yesOrNo = on ? NSLocalizedString(@"On", @"Setting: on") : NSLocalizedString(@"Off", @"Setting: off");;
    return [NSString stringWithFormat:NSLocalizedString(@"Vibration - %@", @"label for vibration setting"), yesOrNo];
}

- (NSString *)colorStringforIndex:(NSInteger)index {
    NSString *color = [[Colors colorSetNames] objectAtIndex:index];;
    return [NSString stringWithFormat:NSLocalizedString(@"Color - %@", @"label for vibration setting"), color];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];

    [defaults setObject:[NSNumber numberWithBool:self.appSettings.vibrationFeedback] forKey:@"vibrationFeedback"];
    [defaults setObject:[NSNumber numberWithInteger:self.appSettings.selectedColorSet] forKey:@"selectedColorSet"];
    [defaults synchronize];
    [super viewWillDisappear:animated];
}

- (void)updateBackgroundColor {
    self.collectionView.backgroundColor = [Colors colorWithIndex:0 usingColorSet:[Colors colorsetWithIndex:2 * self.appSettings.selectedColorSet]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateBackgroundColor];
    // subscribe to device rotation
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redoLayout:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self redoLayout:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.tracker = [[GAI sharedInstance] defaultTracker];
    [self.tracker set:kGAIScreenName value:@"SettingsVC"];
    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

}

- (IBAction)buttonPressed:(UIButton *)sender {
    switch (sender.tag) {
        case TRASHCELL:
            [self deleteAllTrivits];
            break;
        case COLORCELL:
            [self colorButtonPressed];
            break;
        case TUTORIALCELL:
            [self showTutorial];
            break;
        case RESETCELL:
            [self resetAllTrivits];
            break;
        case FEEDBACKCELL:
            [self segueToFeedbackFromButton:sender];
            break;
        case VIBRATIONCELL:
            [self vibrationButtonPressed];
            break;
        default:
            break;
    }
}

- (void)segueToFeedbackFromButton:(id)sender {
    [self performSegueWithIdentifier:@"ShowFeedbackScreen" sender:sender];
}

- (void)colorButtonPressed {
    self.appSettings.selectedColorSet = (self.appSettings.selectedColorSet + 1) % [[Colors colorSetNames] count];

    [self updateBackgroundColor];
    [self.collectionView reloadData];
}


- (void)vibrationButtonPressed {
    self.appSettings.vibrationFeedback = !self.appSettings.vibrationFeedback;
    if (self.appSettings.vibrationFeedback) {
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    }

    [self.collectionView reloadData];
}

- (void)deleteAllTrivits {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.sureToDeleteTitle
                                                    message:NSLocalizedString(@"Are you sure you want to delete all trivits?", @"Message box content")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No", @"")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    [alert show];

}

- (void)resetAllTrivits {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.sureToResetTitle
                                                    message:NSLocalizedString(@"Are you sure you want to reset all counts to 0?", @"Message box content")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No", @"")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    [alert show];

}

- (void)showTutorial {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *tutorialVC = (UINavigationController *) [mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialContainer"];
    [self presentViewController:tutorialVC animated:YES completion:^{
    }];
    
    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                               action:@"Reshow tutorial"
                                                                label:@""
                                                                value:@1] build]];


}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TallyModel"];
        [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID

        NSError *error;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if ([alertView.title isEqualToString:self.sureToDeleteTitle]) {
            for (NSManagedObject *record in fetchedObjects)
                [self.managedObjectContext deleteObject:record];
            
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
            [defaults setObject:nil forKey:@"lastUsedTrivitsIndexes"];
            [defaults setObject:nil forKey:@"lastUsedTrivitsTitles"];
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                                       action:@"All trivits removed"
                                                                        label:@""
                                                                        value:@1] build]];


        }
        if ([alertView.title isEqualToString:self.sureToResetTitle]){
            for (TallyModel *record in fetchedObjects)
                record.counter = [NSNumber numberWithInteger:0];

            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Settings"
                                                                       action:@"All trivits reset to 0"
                                                                        label:@""
                                                                        value:@1] build]];

        }

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
    SettingButtonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"cell_%i", (int) indexPath.item + 1] forIndexPath:indexPath];

    // Configure the cell

    cell.backgroundColor = [Colors colorWithIndex:0 usingColorSet:[Colors colorsetWithIndex:2 * self.appSettings.selectedColorSet + 1]];
    cell.buttonID = indexPath.item;

    switch (cell.buttonID) {
        case TRASHCELL:
            cell.buttonImage = [SettingsIcons imageOfTrash];
            cell.buttonText = NSLocalizedString(@"Remove all", @"remove all trivits button in settings");
            break;
        case COLORCELL:
            cell.buttonImage = [SettingsIcons imageOfColor];
            cell.buttonText = [self colorStringforIndex:self.appSettings.selectedColorSet];
            break;
        case TUTORIALCELL:
            cell.buttonImage = [SettingsIcons imageOfTutorial];
            cell.buttonText = NSLocalizedString(@"Tutorial", @"show tutorial button in settings");
            break;
        case RESETCELL:
            cell.buttonImage = [SettingsIcons imageOfReset];
            cell.buttonText = NSLocalizedString(@"Reset all", @"reset all trivits button in settings");
            break;
        case FEEDBACKCELL:
            cell.buttonImage = [SettingsIcons imageOfFeedback];
            cell.buttonText = NSLocalizedString(@"Feedback", @"send feedback button in settings");
            break;
        case VIBRATIONCELL:
            cell.buttonText = [self vibrationString:self.appSettings.vibrationFeedback];
            cell.buttonImage = [SettingsIcons imageOfVibrate];
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark Collection view layout things

// Layout: Set cell size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    CGSize mElementSize = CGSizeMake(self.cellWidth, self.cellHeight);
    return mElementSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.spacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.spacing;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowFeedbackScreen"]) {
        if ([segue.destinationViewController isKindOfClass:[FeedbackViewController class]]) {
            SettingsViewController *svc = (SettingsViewController *) segue.destinationViewController;
            [svc setManagedObjectContext:self.managedObjectContext];
        }
    }
}

- (void)redoLayout:(NSNotification *)notification {
    int numberOfCellsPerRow = 2;
    int numberOfCellsPerColumn = 3;
    if ( UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
        numberOfCellsPerRow = 3;
        numberOfCellsPerColumn = 2;
    }
    self.spacing = 16;
    CGFloat barHeight = self.navigationController.navigationBar.frame.size.height;
    self.cellWidth = (self.view.frame.size.width - ( numberOfCellsPerRow + 1 ) * self.spacing ) / numberOfCellsPerRow;
    self.cellHeight = (self.view.frame.size.height - barHeight - ( numberOfCellsPerColumn + 2 ) * self.spacing ) / numberOfCellsPerColumn;
    
    if (self.cellHeight > 1.1 * self.cellWidth){
        self.cellHeight = self.cellWidth * 1.1;
    }
    
    if (notification) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }
}

@end
