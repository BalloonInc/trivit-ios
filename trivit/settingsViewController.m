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

@interface SettingsViewController () <UIAlertViewDelegate>
@property(strong, nonatomic, readonly) NSString *sureToDeleteTitle;
@property(strong, nonatomic, readonly) NSString *sureToResetTitle;
@property(nonatomic) int cellHeight;
@property(nonatomic) int cellWidth;
@property(nonatomic) int spacing;

@property(nonatomic) UIDeviceOrientation currentOrientation;
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

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)


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

        }
        if ([alertView.title isEqualToString:self.sureToResetTitle])
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
    self.currentOrientation = [[UIDevice currentDevice] orientation];
    if (IS_IPHONE_4_OR_LESS){
        // for iPhone 4S, smaller tiles in portrait
        self.cellHeight = 124;
        self.cellWidth = 136;
    }
    else if (IS_IPHONE_5){
        self.cellHeight = 136;
        self.cellWidth = 136;
    }
    else if (IS_IPHONE_6){
        self.cellHeight = 164;
        self.cellWidth = 164;
        
    }
    else if (IS_IPHONE_6P){
        self.cellHeight = 178;
        self.cellWidth = 178;
    }
    else{
        self.cellHeight = 124;
        self.cellWidth = 136;
    }
    
    self.spacing = 10;
    
    if (notification) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView reloadData];
    }
}

@end
