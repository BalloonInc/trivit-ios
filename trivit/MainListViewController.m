//
//  MainListViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "MainListViewController.h"
#import "SettingsViewController.h"
#import "Colors.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TallyModel.h"
#import "FeedbackManager.h"
#import "DataAccess.h"

@interface MainListViewController () <NSFetchedResultsControllerDelegate, UIAlertViewDelegate>
@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsControllerSetup;
@property(nonatomic, readonly) NSInteger trivitCount;
@property(strong, nonatomic) NSFetchRequest *fetchRequest;
@property(strong, nonatomic) NSFetchRequest *fetchRequestSetup;
@property(strong, nonatomic) NSIndexPath *shouldScrollToCellAtIndexPath;
@property(nonatomic) bool shouldScrollOnTallyIncreaseOrDecrease;
@property(strong, nonatomic) NSArray *placeholderTrivitTitles;
@property(strong, nonatomic) NSArray *lastFetchedData;
@property(nonatomic) NSInteger imagesPerRow;
@end

@implementation MainListViewController

#pragma mark - Constants
int const CELL_TAP = 0;
int const TITLE_TAP = 1;
int const MINUSBUTTON_TAP = 2;
int const OUTSIDE_TAP = 3;

#pragma mark - lazy instantiatiors

- (NSInteger)trivitCount {
    return [self.managedObjectContext countForFetchRequest:self.fetchRequest error:nil];
}

- (NSInteger)imagesPerRow {
    return (int) floor((self.view.frame.size.width-COLLECTIONVIEW_HORIZONTAL_SPACING) / (TALLY_IMAGE_DIMENSION + COLLECTIONVIEW_HORIZONTAL_SPACING));
}

- (Settings *)appSettings {
    if (!_appSettings) {_appSettings = [[Settings alloc] init];}
    return _appSettings;
}

- (NSString *)trivitExampleNameAtIndex:(NSInteger)index {
    if (!self.placeholderTrivitTitles) {
        NSString *fruits = NSLocalizedString(@"Days in prison,Sport cars owned,Days without holiday,Cups of coffee this year,Days of work left for our app,Days without cursing,People stalked,Unfinished Netflix movies,Tallies added,iPhones owned,Bugs in our software,Beers,Pairs of shoes owned,Rainy days in 2015,Glasses of water,Stars in the sky,Days waiting for Apple Watch release", @"Placeholder texts for newly added trivits");
        self.placeholderTrivitTitles = [fruits componentsSeparatedByString:@","];
    }
    return self.placeholderTrivitTitles[index % self.placeholderTrivitTitles.count];
}

#pragma mark - add item

- (IBAction)addButtonPressed {
    if (self.keyboardShown) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot add", @"messagebox title")
                                                        message:NSLocalizedString(@"Please finish editing the title first.", @"messagebox, adding trivit not possible while editing other trivit")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Got it.", @"OK button")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    self.keyboardShown = true;
    // add consequent identifier to tallies
    [self addItemWithTitle:[self trivitExampleNameAtIndex:[self nextPropertyIndexForNewTally]] andCount:0];

    // decide on delay: if there are not enough cells to fill the view, add a 0.1 seconds delay
    // (this is to make sure editTrivitTitleAtIndexPath always works when adding a trivit)

    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];

    NSInteger rowIndexOfFirstVisibleCell = visibleRows ? [[visibleRows objectAtIndex:0] row] : 0;
    NSInteger rowIndexOfLastVisibleCell = visibleRows ? [[visibleRows lastObject] row] : 0;
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    double delay = ((rowIndexOfFirstVisibleCell == 0 && rowIndexOfLastVisibleCell == numberOfRows - 1)) ? 0.1 : 0;

    [UIView animateWithDuration:0.2 delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionBottom
                                                       animated:NO];
                     }
                     completion:^(BOOL finished) {
                         if (finished) [self performSelector:@selector(editTrivitTitleAtIndexPath:) withObject:nil afterDelay:delay];
                     }];
}

- (void)addItemWithTitle:(NSString *)title andCount:(NSInteger)count {
    // Color index: last tally in the aray +1
    NSInteger colorIndex = [self nextPropertyIndexForNewTally];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:self.managedObjectContext];

    TallyModel *record = [[TallyModel alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    record.title = title;
    record.counter = [NSNumber numberWithInteger:count];
    record.color = [NSNumber numberWithInteger:colorIndex];
    record.type = [[title substringFromIndex:1] isEqualToString:@"_"] ? @"ch_" : @"";
    record.createdAt = [NSDate date];
    
    // Save Record
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        if (error) {
            NSLog(@"Unable to save record.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
    }
}

// function to return the next index to use for new trivit color/tirivit title placeholder
- (NSInteger)nextPropertyIndexForNewTally {
    if (self.trivitCount == 0)
        return 0;
    else {
        TallyModel *lastResult = [[self.managedObjectContext executeFetchRequest:self.fetchRequest error:NULL] objectAtIndex:self.trivitCount - 1];
        return lastResult.color.integerValue + 1;
    }
}

# pragma mark - selectors for gestures

- (void)handleTallyReset:(UIGestureRecognizer *)tapRecognizer {
    if (self.keyboardShown)
        return;
    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:tapRecognizer];
    if (tappedViewIdentifier != OUTSIDE_TAP) {
        CGPoint tapLocation = [tapRecognizer locationInView:self.tableView];
        NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
        TrivitTableViewCell *tappedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:tappedIndexPath];
        if (!tappedCell.isCollapsed) {
            self.activeCellIndexPath = tappedIndexPath;
            [self sureYouWantToReset:tappedCell.tally.title];
        }
    }
}

- (void)sureYouWantToReset:(NSString *)trivitTitle {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Trivit", @"messagebox title")
                                                    message:
                                                            [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to reset '%@'?", @"messagebox text, parameter is title of tally"), trivitTitle]
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No", @"")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:self.activeCellIndexPath];
        record.counter = [NSNumber numberWithInt:0];

        [[self.tableView cellForRowAtIndexPath:self.activeCellIndexPath] setNeedsDisplay]; // update cell
    }
}

- (void)handleTallyIncrease:(UIGestureRecognizer *)singletapRecognizer {
    CGPoint swipeLocation = [singletapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *increasedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:swipedIndexPath];
    increasedCell.loadAnimation = NO;

    if (!increasedCell.isCollapsed) {
        [increasedCell increaseTallyCounter];
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSInteger currentCount = [record.counter integerValue] + 1;

        record.counter = [NSNumber numberWithInteger:currentCount];
        [self buzzIt];
        // if new image ==> redraw cell height
        if (currentCount % (5 * self.imagesPerRow) == 1) {
            // if new row, prepare for scrolling the cell:
            [self scrollToExpandedCell:swipedIndexPath];
            self.shouldScrollOnTallyIncreaseOrDecrease = true;

            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent animations:^{
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }                completion:nil];
        }
    }
}

- (void)handleTallyDecrease:(UIGestureRecognizer *)tapRecognizer {
    if (self.keyboardShown)
        return;

    CGPoint swipeLocation = [tapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *swipedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:swipedIndexPath];

    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:tapRecognizer];
    swipedCell.loadAnimation = NO;

    if (!swipedCell.isCollapsed && (tappedViewIdentifier == CELL_TAP || tappedViewIdentifier == MINUSBUTTON_TAP)) {
        [swipedCell decreaseTallyCounter];

        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSInteger currentCount = [record.counter integerValue] - 1;
        if (currentCount >= 0)
            record.counter = [NSNumber numberWithInteger:currentCount];
        [self buzzIt];
        // if image got removed ==> redraw cell height
        if (currentCount % (5 * self.imagesPerRow) == 0) {
            [self scrollToExpandedCell:swipedIndexPath];
            self.shouldScrollOnTallyIncreaseOrDecrease = true;

            [self.tableView beginUpdates]; // necessary for the animation of the cell growth
            [self.tableView endUpdates]; // necessary for the animation of the cell growth
        }
    }
}

- (void)buzzIt {
    if (self.appSettings.vibrationFeedback) {
         AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    }
}

- (void)handleTallyCollapse:(UIGestureRecognizer *)recognizer {
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *collapseIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *collapseCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:collapseIndexPath];
    // delay for showing trivits
    collapseCell.loadAnimation = YES;

    collapseCell.isCollapsed = !collapseCell.isCollapsed;
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:collapseIndexPath];
    record.isCollapsed = [NSNumber numberWithBool:collapseCell.isCollapsed];

    if (!collapseCell.isCollapsed)
        [self scrollToExpandedCell:collapseIndexPath];
}

- (void)handleTap:(UIGestureRecognizer *)singletapRecognizer {
    if (self.keyboardShown)
        return;

    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:singletapRecognizer];
    if (tappedViewIdentifier == CELL_TAP)
        [self handleTallyIncrease:singletapRecognizer];
    else if (tappedViewIdentifier == TITLE_TAP)
        [self handleTallyCollapse:singletapRecognizer];
    else if (tappedViewIdentifier == MINUSBUTTON_TAP)
        [self handleTallyDecrease:singletapRecognizer];

}

- (NSInteger)tappedViewforGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint tapLocation = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    TrivitTableViewCell *tappedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:tappedIndexPath];
    UIView *tappedView = [self.tableView hitTest:tapLocation withEvent:nil];


    if (tappedView == tappedCell.tallyImageZone)
        return CELL_TAP;
    else if (CGRectContainsPoint(tappedCell.frame, tapLocation)) {
        CGPoint tapLocationInCell = [gestureRecognizer locationInView:tappedCell];
        //button press can be kind of next to the button as well (x pixels from each side, x=fuzzyButtonPressExtension
        float fuzzyButtonPressExtension = 20.;
        CGRect buttonZone = CGRectMake(tappedCell.minusButton.frame.origin.x - fuzzyButtonPressExtension, tappedCell.minusButton.frame.origin.y - fuzzyButtonPressExtension, tappedCell.minusButton.frame.size.width + 2 * fuzzyButtonPressExtension, tappedCell.minusButton.frame.size.height + 2 * fuzzyButtonPressExtension);

        if (!tappedCell.isCollapsed && CGRectContainsPoint(buttonZone, tapLocationInCell))
            return MINUSBUTTON_TAP;
        else
            return TITLE_TAP;
    }
    else
        return OUTSIDE_TAP;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];

    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:recognizer];

    if (recognizer.state == UIGestureRecognizerStateBegan && tappedViewIdentifier == MINUSBUTTON_TAP)
        [self handleTallyReset:recognizer];

    if (recognizer.state == UIGestureRecognizerStateBegan && tappedViewIdentifier == TITLE_TAP){
        [self editTrivitTitleAtIndexPath:indexPath];
        self.keyboardShown = true;
    }
}

- (void)editTrivitTitleAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath)
        indexPath = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1 inSection:0];

    if (self.cellBeingEdited)
        self.cellBeingEdited.titleTextField.enabled = NO;

    TrivitTableViewCell *tappedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    tappedCell.loadAnimation = NO;
    self.cellBeingEdited = tappedCell; //Save cell being edited
    self.activeCellIndexPath = indexPath;     //save indexPath to show after keyboard hides
    tappedCell.titleTextField.enabled = YES;
    [tappedCell.titleTextField becomeFirstResponder];
    [tappedCell.titleTextField selectAll:nil];
}

#pragma mark - cell height calculation

- (float)cellHeigthForTallyCount:(NSInteger)tallyCount // values are based on trial and error
{
    float tally_image_Count = ceil(tallyCount / 5.);

    int rows = ceil(1. * tally_image_Count / self.imagesPerRow);
    if (rows < 2)
        return CELL_HEIGHT_SECTION1 + TALLY_IMAGE_DIMENSION;
    else
        return CELL_HEIGHT_SECTION1 + rows * (TALLY_IMAGE_DIMENSION + COLLECTIONVIEW_VERTICAL_SPACING);
}

#pragma mark - Magic to make the tableview datasource working

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.view.userInteractionEnabled = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath; {
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (![record.isCollapsed boolValue])
        return MAX(CELL_HEIGHT_SECTION1 + CELL_HEIGHT_SECTION2, CELL_HEIGHT_SECTION1 + [self cellHeigthForTallyCount:[record.counter integerValue]]); // Full
    else
        return CELL_HEIGHT_SECTION1; // Only first section of the cell (title UILabel) (if cell is not selected... seems always to be the case
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TrivitTableViewCell *cell = [[TrivitTableViewCell alloc] init];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(TrivitTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.appSettings = self.appSettings;
    bool isCollapsed = [record.isCollapsed boolValue];
    if (cell.isCollapsed != isCollapsed)
        cell.isCollapsed = isCollapsed;
    cell.tally.counter = [record.counter integerValue];
    cell.tally.colorIndex = [record.color integerValue];
    cell.tally.title = record.title;
    cell.tally.type = record.type;

    cell.cellIdentifier = (int) indexPath.row;
    if (!cell.titleTextField.delegate)
        cell.titleTextField.delegate = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];

    return [sectionInfo numberOfObjects];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !self.keyboardShown;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    TrivitTableViewCell *cell = (TrivitTableViewCell*) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.loadAnimation=true;

}

-(void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    TrivitTableViewCell *cell = (TrivitTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.loadAnimation=true;

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (record)
            [self.fetchedResultsController.managedObjectContext deleteObject:record];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    // if necessary, scroll to show cell
    // the scroll logic is here to ensure it is executed after the cell is expanded
    if (self.shouldScrollToCellAtIndexPath)
        [self.tableView scrollToRowAtIndexPath:self.shouldScrollToCellAtIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    // on next GUI update, do not scroll anymore
    self.shouldScrollToCellAtIndexPath = nil;
    [self saveData];
}

- (void)scrollToExpandedCell:(NSIndexPath *)indexPath {
    NSArray *visibleRows = [self.tableView visibleCells];

    // get last cell visible in the current view
    TrivitTableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *lastIndexPath = [self.tableView indexPathForCell:lastVisibleCell];

    self.shouldScrollToCellAtIndexPath = nil;
    switch (lastIndexPath.row - indexPath.row) {
        case 0:
            self.shouldScrollToCellAtIndexPath = indexPath;
            break;
        case 1:
            if (lastVisibleCell.isCollapsed && !self.shouldScrollOnTallyIncreaseOrDecrease)
                self.shouldScrollToCellAtIndexPath = indexPath;
            break;
        case 2: {
            TrivitTableViewCell *oneButLastVisibleCell = [[visibleRows subarrayWithRange:NSMakeRange(([visibleRows count] - 2), 1)] firstObject];
            if (lastVisibleCell.isCollapsed && oneButLastVisibleCell.isCollapsed && !self.shouldScrollOnTallyIncreaseOrDecrease)
                self.shouldScrollToCellAtIndexPath = indexPath;
            break;
        }
        default:
            break;
    }
    self.shouldScrollOnTallyIncreaseOrDecrease = false;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if(indexPath.row<self.activeCellIndexPath.row)
                self.activeCellIndexPath = [NSIndexPath indexPathForRow:self.activeCellIndexPath.row-1 inSection:0];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

- (void)orientationChanged:(NSNotification *)notification {
    for (TrivitTableViewCell *cell in [self.tableView visibleCells]) {
        if (!cell.isCollapsed)
            cell.reloadCompleteCell = true;
        cell.cellWillRotate=YES;
    }
}

#pragma mark - view load stuff

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableView];

    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];

    
    self.fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TallyModel"];
    [self.fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];

    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];

    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    
    self.lastFetchedData = [DataAccess copyLastFetchedData:self.fetchedResultsController.fetchedObjects];

    if (![[self.defaults objectForKey:@"tutorialShown"] boolValue]) {
        [self addItemWithTitle:NSLocalizedString(@"Swipe left to delete", @"Tally example") andCount:0];
        [self addItemWithTitle:NSLocalizedString(@"Days without cookies", @"Tally example") andCount:24];
        [self addItemWithTitle:NSLocalizedString(@"Went swimming this year", @"Tally example") andCount:8];
        TrivitTableViewCell *cell = (TrivitTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        cell.isCollapsed = false;
    }
    else {
        self.appSettings.vibrationFeedback = [[self.defaults objectForKey:@"vibrationFeedback"] boolValue];
        self.appSettings.selectedColorSet = [[self.defaults objectForKey:@"selectedColorSet"] integerValue];
    }

    // subscribe to notifications for keyboard show and hide, used for changing view size
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];
}

-(void)saveData{
    [DataAccess.sharedInstance saveManagedObjectContext];
}


-(void) reloadData:(NSTimer *)timer{
    if(self.cellBeingEdited)
        return;
    
        DataAccess.sharedInstance.managedObjectContext=nil;
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:DataAccess.sharedInstance.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        self.managedObjectContext=DataAccess.sharedInstance.managedObjectContext;

        //refetch
        NSError *error = nil;
        [self.fetchedResultsController performFetch:&error];
            [self.fetchedResultsController setDelegate:self];

        if (error) {
            NSLog(@"Unable to perform fetch.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        
    NSInteger difference = [DataAccess whatIsUpdatedForOldArray:self.lastFetchedData andNewArray:self.fetchedResultsController.fetchedObjects];
        // save lastfetcheddata to see if updates are needed
        self.lastFetchedData = [DataAccess copyLastFetchedData:self.fetchedResultsController.fetchedObjects];
    if (difference>0)
        [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // show tutorial if needed
    if (![[self.defaults objectForKey:@"tutorialShown"] boolValue]) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController *tutorialVC = (UINavigationController *) [mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialContainer"];
        [self presentViewController:tutorialVC animated:YES completion:^{
        }];
    }
}

- (void)resendUnsentFeedback {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Feedback"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"scaleValue" ascending:YES]]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    [fetchedResultsController setDelegate:self];

    NSError *error = nil;
    [fetchedResultsController performFetch:&error];

    if (error) {
        NSLog(@"Unable to perform fetch.\n%@, %@", error, error.localizedDescription);
        return;
    }
    for (Feedback *f in [fetchedResultsController fetchedObjects])
        [[FeedbackManager alloc] feedbackWithObject:f managedObjectContext:self.managedObjectContext];
}

- (void)configureTableView {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longTap.minimumPressDuration = 0.2;

    [self.tableView addGestureRecognizer:tap];
    [self.tableView addGestureRecognizer:longTap];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableViewBackgroundTally"]];
    imageView.contentMode = UIViewContentModeCenter; // don't allow rescaling of the image
    self.tableView.backgroundColor = [Colors colorWithHexString:@"F5F4F4"];
    self.tableView.backgroundView = imageView; // add UIImageView to the tableView background
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.cellBeingEdited = nil;
    if ([segue.identifier isEqualToString:@"ShowSettingsForTrivit"]) {
        if ([segue.destinationViewController isKindOfClass:[SettingsViewController class]]) {
            SettingsViewController *svc = (SettingsViewController *) segue.destinationViewController;
            svc.appSettings = self.appSettings;
            [svc setManagedObjectContext:self.managedObjectContext];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    // reload data in case the color would have changed
    // TODO: check if appSettings.selectedColorSet has changed and only refresh if it is true
    // we should make a NSNumber number with boolean and pass it in the prepareforsegue (nsnumber is passed by reference)
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self resendUnsentFeedback];
}

#pragma mark - view resize on keyboard show

- (void)keyboardWasShown:(NSNotification *)aNotification {

    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, kbSize.height, self.tableView.contentInset.right);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;

    TrivitTableViewCell *activeCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:self.activeCellIndexPath];

    if (!CGRectContainsPoint(aRect, activeCell.frame.origin))
        [self.tableView scrollRectToVisible:activeCell.frame animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:self.activeCellIndexPath];

    if (self.cellBeingEdited.titleTextField != nil) {
        record.title = self.cellBeingEdited.titleTextField.text;
        NSString *tallyType = (self.cellBeingEdited.titleTextField.text.length > 0) && [[self.cellBeingEdited.titleTextField.text substringToIndex:1] isEqual:@"_"] ? @"ch_" : @"";
        record.type = tallyType;
    }

    self.cellBeingEdited.titleTextField.enabled = NO;
    self.activeCellIndexPath = nil;
    self.cellBeingEdited = nil;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 0, self.tableView.contentInset.right);

    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

    self.keyboardShown = false;
}

@end
