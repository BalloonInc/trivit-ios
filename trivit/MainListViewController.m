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
#import <WatchConnectivity/WatchConnectivity.h>
#import <Google/Analytics.h>

@interface MainListViewController () <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, WCSessionDelegate>
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
@property(strong,nonatomic) NSString *startupAction;
@property(nonatomic) NSInteger indexAtStartup;
@property(strong,nonatomic) id<GAITracker> tracker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;
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

#pragma mark - last edited trivits

-(void) removeFromLastEditedTrivits: (NSInteger) indexOfTrivitToRemove{
    NSMutableArray *lastUsedTrivitsIndexes = [[self.defaults objectForKey:@"lastUsedTrivitsIndexes"] mutableCopy];
    NSMutableArray *lastUsedTrivitsTitles = [[self.defaults objectForKey:@"lastUsedTrivitsTitles"] mutableCopy];
        
    NSUInteger indexToRemove = [lastUsedTrivitsIndexes indexOfObjectIdenticalTo:[NSNumber numberWithInteger:indexOfTrivitToRemove]];
    if(indexToRemove != NSNotFound){
        [lastUsedTrivitsIndexes removeObjectAtIndex:indexToRemove];
        [lastUsedTrivitsTitles removeObjectAtIndex:indexToRemove];
    }
    
    for (int i=0; i<[lastUsedTrivitsIndexes count]; i++) {
        if ([lastUsedTrivitsIndexes[i] integerValue]>indexOfTrivitToRemove)
            lastUsedTrivitsIndexes[i] = [NSNumber numberWithInteger:[lastUsedTrivitsIndexes[i] integerValue]-1];
    }
    
    [self.defaults setObject:lastUsedTrivitsIndexes forKey:@"lastUsedTrivitsIndexes"];
    [self.defaults setObject:lastUsedTrivitsTitles forKey:@"lastUsedTrivitsTitles"];
}

- (void) updateLastEditedTrivits: (NSInteger)indexOflatestTrivit {
    
    NSMutableArray *lastUsedTrivitsIndexes = [[self.defaults objectForKey:@"lastUsedTrivitsIndexes"] mutableCopy];
    NSMutableArray *lastUsedTrivitsTitles = [[self.defaults objectForKey:@"lastUsedTrivitsTitles"] mutableCopy];
    
    if(!lastUsedTrivitsIndexes){
        lastUsedTrivitsIndexes = [[NSMutableArray alloc] init];
        lastUsedTrivitsTitles = [[NSMutableArray alloc] init];
    }
    
    TrivitTableViewCell *lastCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexOflatestTrivit inSection:0]];
    
    //cell may not be found, don't try to remove and insert nil
    if(!lastCell)
        return;
    NSUInteger indexToRemove = [lastUsedTrivitsIndexes indexOfObjectIdenticalTo:[NSNumber numberWithInteger:indexOflatestTrivit]];

    if(indexToRemove != NSNotFound){
        [lastUsedTrivitsIndexes removeObjectAtIndex:indexToRemove];
        [lastUsedTrivitsTitles removeObjectAtIndex:indexToRemove];
    }
    
    [lastUsedTrivitsIndexes addObject:[NSNumber numberWithInteger:indexOflatestTrivit]];
    [lastUsedTrivitsTitles addObject:lastCell.titleTextField.text];
    
    [self.defaults setObject:lastUsedTrivitsIndexes forKey:@"lastUsedTrivitsIndexes"];
    [self.defaults setObject:lastUsedTrivitsTitles forKey:@"lastUsedTrivitsTitles"];

}


#pragma mark - add item

-(void) addNewTrivitAtStartup{
    self.startupAction=@"AddNewTrivit";
}
-(void)incrementTrivitAtStartup:(NSInteger)index{
    self.indexAtStartup = index;
    self.startupAction=@"IncrementTrivit";
}
-(void)jumpToTrivitAtStartup:(NSInteger)index{
    self.indexAtStartup = index;
    self.startupAction=@"JumpToTrivit";
}

-(void) addNewTrivit {
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

- (IBAction)addButtonPressed {
    [self addNewTrivit];
}

- (IBAction)editButtonPressed:(id)sender {
    if ([[self tableView] isEditing]){
        [[self tableView] setEditing:false];
        [[self editButton] setTitle:@"Edit"];
    }
    else {
        [[self tableView] setEditing:true];
        [[self editButton] setTitle:@"Done"];
    }
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
    
    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"TrivitEdit"
                                                               action:@"Add from iOS"
                                                                label:[NSString stringWithFormat:@"'%@'",record.title]
                                                                value:@1] build]];

    
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
        [self updateLastEditedTrivits:tappedIndexPath.row];
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
        [self saveData];
    }
}

- (void)handleTallyIncrease:(UIGestureRecognizer *)singletapRecognizer {
    CGPoint swipeLocation = [singletapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    [self incrementTrivitAtIndexPath:swipedIndexPath withFlash:false];
}

-(void) incrementTrivitAtIndexPath:(NSIndexPath *)indexPath withFlash: (BOOL) flash{
    TrivitTableViewCell *increasedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    increasedCell.loadAnimation = NO;
    
    if (!increasedCell.isCollapsed) {
        [increasedCell increaseTallyCounter];
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSInteger currentCount = [record.counter integerValue] + 1;
        
        [self updateLastEditedTrivits:indexPath.row];
        
        record.counter = [NSNumber numberWithInteger:currentCount];

        [self buzzIt];
        // if new image ==> redraw cell height
        if (currentCount % (5 * self.imagesPerRow) == 1) {
            // if new row, prepare for scrolling the cell:
            [self scrollToExpandedCell:indexPath];
            self.shouldScrollOnTallyIncreaseOrDecrease = true;
            
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionAllowAnimatedContent animations:^{
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }
           completion:nil];
        }
        if(flash)
            [increasedCell flashIncrement];
    }
    [self saveData];
}

- (void)handleTallyDecrease:(UIGestureRecognizer *)tapRecognizer {
    if (self.keyboardShown)
        return;

    CGPoint swipeLocation = [tapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *swipedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:swipedIndexPath];

    [self updateLastEditedTrivits:swipedIndexPath.row];

    
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
    [self saveData];
}

- (void)buzzIt {
    if (self.appSettings.vibrationFeedback) {
         AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    }
}

- (void)handleTallyCollapse:(UIGestureRecognizer *)recognizer {
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *collapseIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    [self collapseTrivitAtIndexPath:collapseIndexPath];
}
- (void) collapseTrivitAtIndexPath: (NSIndexPath *)indexPath{
    TrivitTableViewCell *collapseCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    // delay for showing trivits
    collapseCell.loadAnimation = YES;
    
    collapseCell.isCollapsed = !collapseCell.isCollapsed;
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    record.isCollapsed = [NSNumber numberWithBool:collapseCell.isCollapsed];
    
    if (!collapseCell.isCollapsed)
        [self scrollToExpandedCell:indexPath];
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
       [self endEditTrivitTitle];

    TrivitTableViewCell *tappedCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];

    tappedCell.loadAnimation = NO;
    self.cellBeingEdited = tappedCell; //Save cell being edited
    self.activeCellIndexPath = indexPath;     //save indexPath to show after keyboard hides
    tappedCell.titleTextField.enabled = YES;
    tappedCell.parentViewController=self;
    [tappedCell.titleTextField becomeFirstResponder];
    [tappedCell.titleTextField selectAll:nil];
}

-(void)endEditTrivitTitle{
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:self.activeCellIndexPath];
    
    if (self.cellBeingEdited.titleTextField != nil) {
        [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"TrivitEdit"
                                                              action:@"Rename"
                                                               label:[NSString stringWithFormat:@"'%@' (was '%@')",self.cellBeingEdited.titleTextField.text,record.title]
                                                               value:@1] build]];

        record.title = self.cellBeingEdited.titleTextField.text;
        NSString *tallyType = (self.cellBeingEdited.titleTextField.text.length > 0) && [[self.cellBeingEdited.titleTextField.text substringToIndex:1] isEqual:@"_"] ? @"ch_" : @"";
        record.type = tallyType;
    }
    [self updateLastEditedTrivits:self.activeCellIndexPath.row];

    self.cellBeingEdited.titleTextField.enabled = NO;
    self.activeCellIndexPath = nil;
    self.cellBeingEdited = nil;

    self.keyboardShown = false;
    [self saveData];
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

#pragma mark - UITableView datasource working

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
    [cell setNeedsLayout];
    [cell setNeedsDisplay];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];

    return [sectionInfo numberOfObjects];
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *moreButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Color" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                    {
                                        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
                                        if (record){
                                            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"TrivitEdit"
                                                                                                       action:@"ToggleColor"
                                                                                                        label:[NSString stringWithFormat:@"'%@'",record.title]
                                                                                                        value:@1] build]];
                                            
                                            record.color = [NSNumber numberWithInt:[record.color intValue] + 1];

                                            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                                        }
                                    }];
    moreButton.backgroundColor = [UIColor colorWithRed:0.295
                                                      green:0.851
                                                       blue:0.392
                                                      alpha:1.0f];
    UITableViewRowAction *deleteButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                     {
                                         TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
                                         if (record){
                                             [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"TrivitEdit"
                                                                                                        action:@"Delete"
                                                                                                         label:[NSString stringWithFormat:@"'%@'",record.title]
                                                                                                         value:@1] build]];
                                             
                                             [self.fetchedResultsController.managedObjectContext deleteObject:record];
                                             [self removeFromLastEditedTrivits: indexPath.row];
                                         }
                                     }];
    
    return @[deleteButton, moreButton];
}



- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    return;
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

- (void) scrollAndExpandTrivitAtIndex: (NSInteger) index withFlash: (BOOL) flash completion: (void (^)(void))completionblock{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
    
    if (!self.tableView)
        NSLog(@"TableView does not exist");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        TrivitTableViewCell *cell;
        int i = 0;
        
        while(!cell && i<20){
            cell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
            if (!cell){
                i++;
                [NSThread sleepForTimeInterval:0.2];
            }
            else{
                if (cell.isCollapsed){
                    [self performSelectorOnMainThread:@selector(collapseTrivitAtIndexPath:) withObject:indexPath waitUntilDone:YES];
                    [NSThread sleepForTimeInterval:1.0]; // duration of animation of expansion
                }
                if(flash)
                    [cell performSelectorOnMainThread:@selector(flashTrivit) withObject:nil waitUntilDone:YES];
            }
        }
        if (completionblock)
            dispatch_async( dispatch_get_main_queue(), completionblock);
    });
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self saveData];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            if(indexPath.row<self.activeCellIndexPath.row)
                self.activeCellIndexPath = [NSIndexPath indexPathForRow:self.activeCellIndexPath.row-1 inSection:0];
            [self saveData];
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
    
    if ([WCSession isSupported]){
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }

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
    
    self.lastFetchedData = [self copyLastFetchedData:self.fetchedResultsController.fetchedObjects];

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tracker = [[GAI sharedInstance] defaultTracker];
    [self.tracker set:kGAIScreenName value:@"MainListVC"];
    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    // show tutorial if needed
    if (![[self.defaults objectForKey:@"tutorialShown"] boolValue]) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController *tutorialVC = (UINavigationController *) [mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialContainer"];
        [self presentViewController:tutorialVC animated:YES completion:^{
        }];
    }
    else{
        [self applicationDidBecomeActive:nil];
    }
    self.viewAppeared = true;
    [self saveData];
}

- (void)viewWillAppear:(BOOL)animated {
    // reload data in case the color would have changed
    // TODO: check if appSettings.selectedColorSet has changed and only refresh if it is true
    // we should make a NSNumber number with boolean and pass it in the prepareforsegue (nsnumber is passed by reference)
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self resendUnsentFeedback];
}

-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.viewAppeared = false;
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

-(void) applicationDidBecomeActive:(NSTimer *)timer{
    if (self.startupAction){
        if ([self.startupAction isEqualToString:@"AddNewTrivit"]){
            [self addNewTrivit];
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Startup"
                                                                       action:@"Add"
                                                                        label:@"added from 3D Touch"
                                                                        value:@1] build]];
            self.startupAction=nil;
        }
        else if ([self.startupAction isEqualToString:@"IncrementTrivit"]){
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Startup"
                                                                       action:@"increment"
                                                                        label:@"increment from 3D Touch"
                                                                        value:@1] build]];

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.indexAtStartup inSection:0];
            [self scrollAndExpandTrivitAtIndex:indexPath.row withFlash:false completion:^{
                [self incrementTrivitAtIndexPath:indexPath withFlash:true];
            }];
            self.startupAction=nil;
            self.indexAtStartup=-1;
        }
        else if ([self.startupAction isEqualToString:@"JumpToTrivit"]){
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Startup"
                                                                       action:@"jump"
                                                                        label:@"jump to trivit"
                                                                        value:@1] build]];

            if(self.indexAtStartup<self.trivitCount)
                [self scrollAndExpandTrivitAtIndex:self.indexAtStartup withFlash:true completion:nil];
            self.startupAction=nil;
            self.indexAtStartup=-1;
        }
    }
}

-(NSDictionary*) getEncodedTrivits{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (TallyModel *record in self.fetchedResultsController.fetchedObjects) {
        NSData *encodedRecord = [NSKeyedArchiver archivedDataWithRootObject: record];
        NSString *timeString = [NSString stringWithFormat:@"%f", [record.createdAt timeIntervalSince1970]];
        [dict setObject:encodedRecord forKey:timeString];
    }
    return dict;
}

-(void)saveData{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(!self.cellBeingEdited)
            [DataAccess.sharedInstance saveManagedObjectContext];
        
        WCSession *session = [WCSession defaultSession];
        if (session != nil && session.isPaired && session.isWatchAppInstalled){
            
            NSError *anyError;
            if (![[WCSession defaultSession] updateApplicationContext:[self getEncodedTrivits] error:&anyError]) {
                NSLog(@"updateApplicationContext failed with error %@", anyError);
            }
        }
    });
}

#pragma mark - Watch Connectivity

-(void) session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
    for (NSString *key in userInfo) {
        if ([key isEqual: @"updatedTrivit"]){
            TallyModel *updatedTally = [NSKeyedUnarchiver unarchiveObjectWithData:userInfo[key]];
            
            for (TallyModel *record in [self.fetchedResultsController fetchedObjects] ) {

                if ([record.createdAt compare: updatedTally.createdAt] == NSOrderedSame){
                    NSLog(@"Got updated count for tally %@: count: %i",updatedTally.title, [updatedTally.counter intValue]);

                    record.counter = updatedTally.counter;
                    record.title = updatedTally.title;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }
            }
        }
        else if ([key isEqualToString:@"newTrivit"]){

            TallyModel *newTally = [NSKeyedUnarchiver unarchiveObjectWithData:userInfo[key]];
            [self.managedObjectContext insertObject:newTally];
            NSLog(@"Got new trivit: %@: count: %i",newTally.title, [newTally.counter intValue]);
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"TrivitEdit"
                                                                       action:@"AddFromWatch"
                                                                        label:[NSString stringWithFormat:@"'%@'",newTally.title]
                                                                        value:@1] build]];
            // Save Record
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                if (error) {
                    NSLog(@"Unable to save record.");
                    NSLog(@"%@, %@", error, error.localizedDescription);
                }
            }
            [DataAccess.sharedInstance saveManagedObjectContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else if ([key isEqualToString:@"deleteTrivit"]){
            
            TallyModel *tallyToRemove = [NSKeyedUnarchiver unarchiveObjectWithData:userInfo[key]];

            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TallyModel"];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"createdAt == %@", tallyToRemove.createdAt]];
            NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
            if (results.count == 1){
                [self.managedObjectContext deleteObject:[results objectAtIndex:0]];
            }


             NSLog(@"Delete from Watch: %@: count: %i",tallyToRemove.title, [tallyToRemove.counter intValue]);
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"TrivitRemove"
                                                                       action:@"RemoveFromWatch"
                                                                        label:[NSString stringWithFormat:@"'%@'",tallyToRemove.title]
                                                                        value:@1] build]];
            // Save Record
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                if (error) {
                    NSLog(@"Unable to save record.");
                    NSLog(@"%@, %@", error, error.localizedDescription);
                }
            }
            [DataAccess.sharedInstance saveManagedObjectContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }
}

-(void) session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    for (NSString *key in message) {
        if ([key isEqualToString:@"getLatestStatus"]) {
            replyHandler([self getEncodedTrivits]);
        }
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
    
    NSArray *watchFeedback = [self.defaults objectForKey:@"WatchFeedbackArray"];
    
    for (NSArray *feedback in watchFeedback) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feedback" inManagedObjectContext:self.managedObjectContext];
        
        // Initialize Record
        Feedback *dataObject = [[Feedback alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        dataObject.feedbackMessage = [feedback objectAtIndex:0];
        dataObject.scaleValue = [NSNumber numberWithInt:500];
        dataObject.softwareIdentifier = [feedback objectAtIndex:1];
        dataObject.deviceIdentifier = [feedback objectAtIndex:2];
        dataObject.name = [feedback objectAtIndex:3];
        dataObject.email = @"";
        
        [[FeedbackManager alloc] feedbackWithObject:dataObject managedObjectContext:self.managedObjectContext];
    }
    [self.defaults setObject:nil forKey:@"WatchFeedbackArray"];
    [self.defaults synchronize];
    
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
    [self endEditTrivitTitle];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 0, self.tableView.contentInset.right);

    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}


-(NSArray*) copyLastFetchedData:(NSArray*)fetchedObjects{
    NSMutableArray* lastFetchedData = [[NSMutableArray alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:DataAccess.sharedInstance.managedObjectContext];
    for (TallyModel* tm in fetchedObjects) {
        TallyModel *t = [[TallyModel alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
        t.title=tm.title;
        t.counter=tm.counter;
        [lastFetchedData addObject:t];
    }
    return lastFetchedData;
}

@end
