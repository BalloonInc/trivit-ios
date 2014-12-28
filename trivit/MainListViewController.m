//
//  MainListViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "MainListViewController.h"
#import "TrivitTableViewCell.h"
#import "SettingsViewController.h"
#import "Colors.h"
#import <CoreData/CoreData.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AppDelegate.h"
#import "TallyModel.h"

@interface MainListViewController ()<NSFetchedResultsControllerDelegate,UIAlertViewDelegate>
@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsControllerSetup;
@property(nonatomic, readonly) NSInteger trivitCount;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSFetchRequest *fetchRequestSetup;
@property (strong,nonatomic) NSIndexPath *shouldScrollToCellAtIndexPath;
@property (nonatomic) bool shouldScrollOnTallyIncreaseOrDecrease;

@property (nonatomic) NSInteger imagesPerRow;
@end


@implementation MainListViewController

#pragma mark - Constants
int const CELL_TAP = 0;
int const TITLE_TAP = 1;
int const MINUSBUTTON_TAP = 2;
int const OUTSIDE_TAP = 3;

#pragma mark - lazy instantiatiors

-(NSInteger) trivitCount
{
    NSError *err;
    return [self.managedObjectContext countForFetchRequest:self.fetchRequest error:&err];
}
-(NSInteger) imagesPerRow{
    return (int) floor(self.view.frame.size.width / (TALLY_IMAGE_DIMENSION+COLLECTIONVIEW_VERTICAL_SPACING)+1);
    
}

@synthesize appSettings=_appSettings;

-(Settings*) appSettings{
    if(!_appSettings){_appSettings=[[Settings alloc ] init];}
    return _appSettings;
}

-(void) setAppSettings:(Settings *)appSettings
{
    _appSettings=appSettings;
}

#pragma mark - add item

-(IBAction) addButtonPressed
{
    if(self.keyboardShown||self.trivitRecentlyAdded){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot add",@"messagebox title")
                                                        message:
                               NSLocalizedString(@"Please finish editing the title first", @"messagebox text, adding a trivit not possible since you are editing the title of another trivit")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Got it.",@"OK button")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // add consequent identifier to tallies
    [self addItemWithTitle:[NSString stringWithFormat:@"newTally_%lu",(unsigned long)self.trivitCount]];
    self.trivitRecentlyAdded=true;
    [self performSelector:@selector(setTrivitRecentlyAdded:) withObject:false afterDelay:0.5];
    
    // decide on delay: if there are not enough cells to fill the view, add a 0.1 seconds delay
    // (this is to make sure editTrivitTitleAtIndexPath always works when adding a trivit)
    // note to future self: sorry for the fucked up logic, but it works for now
    // if it breaks, good luck figuring this stuff below out again (maybe next time try to code a bit cleaner from the beginning...)

    NSArray * visibleRows =[self.tableView indexPathsForVisibleRows];
    
    NSInteger rowIndexOfFirstVisibleCell = visibleRows?[[visibleRows objectAtIndex:0] row]:0;
    NSInteger rowIndexOfLastVisibleCell = visibleRows?[[visibleRows lastObject] row ]:0;
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    float delay = ((rowIndexOfFirstVisibleCell==0 && rowIndexOfLastVisibleCell == numberOfRows-1))?0.1:0;
    
    [UIView animateWithDuration:0.2 delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0]-1 inSection:0]
                                               atScrollPosition:UITableViewScrollPositionBottom
                                                       animated:NO];}
                     completion:^(BOOL finished){
                         if(finished)     [self performSelector:@selector(editTrivitTitleAtIndexPath:) withObject:nil afterDelay:delay];}];
}

-(void) addItem
{
    [self addItemWithTitle:@"newTally"];
}

-(void) addItemWithTitle:(NSString*)title
{
    [self addItemWithTitle:title andCount:0];
}

-(void) addItemWithTitle: (NSString*)title andCount: (NSInteger)count
{
    // Color index: last tally in the aray +1
    NSInteger colorIndex;
    
    if (self.trivitCount==0)
        colorIndex=0;
    else{
        TallyModel *lastResult = [[self.managedObjectContext executeFetchRequest:self.fetchRequest error:NULL] objectAtIndex:self.trivitCount-1];
        colorIndex = lastResult.color.integerValue+1;
    }
    
    // Create Entity
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:self.managedObjectContext];
    
    // Initialize Record
    TallyModel *record = [[TallyModel alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    
    // Populate Record
    record.title = title;
    record.counter = [NSNumber numberWithInteger:count];
    record.color = [NSNumber numberWithInteger:colorIndex];
    record.type = [[title substringFromIndex:1] isEqualToString:@"_"]?@"ch_":@"";
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

# pragma mark - selectors for gestures

-(void) handleTallyReset: (UIGestureRecognizer *)tapRecognizer
{
    // if a cell title is being edited don't process taps
    if (self.keyboardShown||self.trivitRecentlyAdded)
        return;
    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:tapRecognizer];
    if(tappedViewIdentifier!=OUTSIDE_TAP){
        CGPoint tapLocation = [tapRecognizer locationInView:self.tableView];
        NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
        TrivitTableViewCell *tappedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:tappedIndexPath];
        if(!tappedCell.isCollapsed){
            self.activeCellIndexPath = tappedIndexPath;
            [self sureYouWantToReset: tappedCell.tally.title];
        }
    }
}

-(void)sureYouWantToReset: (NSString *) trivitTitle
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Trivit",@"messagebox title")
                                                    message:
                          [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to reset '%@'?", @"messagebox text, parameter is title of tally"), trivitTitle]
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No",@"")
                                          otherButtonTitles:NSLocalizedString(@"Yes",@""), nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:self.activeCellIndexPath];
        record.counter = [NSNumber numberWithInt:0];

        [[self.tableView cellForRowAtIndexPath:self.activeCellIndexPath] setNeedsDisplay];
        }
}

-(void) handleTallyIncrease: (UIGestureRecognizer *)singletapRecognizer
{
    CGPoint swipeLocation = [singletapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *increasedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    increasedCell.loadAnimation = NO;
    
    if(!increasedCell.isCollapsed){
        
        [increasedCell increaseTallyCounter];
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSInteger currentCount = [record.counter integerValue]+1;

        record.counter = [NSNumber numberWithInteger:currentCount];
        [self buzzIt];
        // if new image ==> redraw cell height
        if (currentCount%(5*self.imagesPerRow)==1){
            // if new row, prepare for scrolling the cell:
            [self scrollToExpandedCell:swipedIndexPath];
            self.shouldScrollOnTallyIncreaseOrDecrease=true;
            
            [UIView animateWithDuration:0.2  delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent animations:^{
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            } completion:^(BOOL finished){}];
        }
    }
}

-(void) handleTallyDecrease: (UIGestureRecognizer *)tapRecognizer
{
    // if a cell title is being edited don't process taps
    if (self.keyboardShown||self.trivitRecentlyAdded)
        return;
    
    CGPoint swipeLocation = [tapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *swipedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    
    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:tapRecognizer];
    swipedCell.loadAnimation = NO;

   
    if(!swipedCell.isCollapsed && (tappedViewIdentifier==CELL_TAP||tappedViewIdentifier==MINUSBUTTON_TAP)){
        [swipedCell decreaseTallyCounter];
        
        TallyModel *record = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSInteger currentCount = [record.counter integerValue]-1;
        if (currentCount >= 0)
            record.counter = [NSNumber numberWithInteger:currentCount];
        [self buzzIt];
        // if image got removed ==> redraw cell height
        if (currentCount%(5*self.imagesPerRow)==0){
            [self scrollToExpandedCell:swipedIndexPath];
            self.shouldScrollOnTallyIncreaseOrDecrease=true;
            
            [self.tableView beginUpdates]; // necessary for the animation of the cell growth
            [self.tableView endUpdates]; // necessary for the animation of the cell growth
        }
    }
}

-(void)buzzIt
{
    if (self.appSettings.vibrationFeedback){
        NSMutableArray* arr = [NSMutableArray arrayWithObjects:
                               [NSNumber numberWithBool:YES],
                               [NSNumber numberWithInt:50], nil];
        
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              arr,@"VibePattern",
                              [NSNumber numberWithFloat:.85],@"Intensity",nil];
        
        //declare function before usage
        int AudioServicesPlaySystemSoundWithVibration();
        
        AudioServicesPlaySystemSoundWithVibration(4095,nil,dict);
    }

}

-(void) handleTallyCollapse: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *collapseIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *collapseCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:collapseIndexPath];
    // delay for showing trivits
    collapseCell.loadAnimation = YES;
    
    collapseCell.isCollapsed = !collapseCell.isCollapsed;
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:collapseIndexPath];
    record.isCollapsed = [NSNumber numberWithBool:collapseCell.isCollapsed];
    
    // in case of an expansion, potentially scroll down to show expanded cell
    if(!collapseCell.isCollapsed)
        [self scrollToExpandedCell:collapseIndexPath];
}

-(void)handleTap: (UIGestureRecognizer *)singletapRecognizer
{
    // if a cell title is being edited don't process taps
    if (self.keyboardShown|self.trivitRecentlyAdded)
        return;
    
    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:singletapRecognizer];
    if(tappedViewIdentifier==CELL_TAP)
        [self handleTallyIncrease:singletapRecognizer];
    else if (tappedViewIdentifier==TITLE_TAP)
        [self handleTallyCollapse:singletapRecognizer];
    else if (tappedViewIdentifier==MINUSBUTTON_TAP)
        [self handleTallyDecrease:singletapRecognizer];

}

-(NSInteger)tappedViewforGestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapLocation = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    TrivitTableViewCell *tappedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:tappedIndexPath];
    UIView *tappedView = [self.tableView hitTest:tapLocation withEvent:nil];
    
    
    if(tappedView==tappedCell.tallyImageZone)
        return CELL_TAP;
    else if (CGRectContainsPoint(tappedCell.frame, tapLocation))
    {
        CGPoint tapLocationInCell = [gestureRecognizer locationInView:tappedCell];
        //button press can be kind of next to the button as well (x pixels from each side, x=fuzzyButtonPressExtension
        float fuzzyButtonPressExtension = 20.;
        CGRect buttonZone= CGRectMake(tappedCell.minusButton.frame.origin.x-fuzzyButtonPressExtension, tappedCell.minusButton.frame.origin.y-fuzzyButtonPressExtension, tappedCell.minusButton.frame.size.width+2*fuzzyButtonPressExtension, tappedCell.minusButton.frame.size.height+2*fuzzyButtonPressExtension);
        
        if(!tappedCell.isCollapsed && CGRectContainsPoint(buttonZone, tapLocationInCell))
            return MINUSBUTTON_TAP;
        else
            return TITLE_TAP;
    }
    else
        return OUTSIDE_TAP;
}

-(void)handleLongPress:(UILongPressGestureRecognizer * )recognizer
{
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    
    NSInteger tappedViewIdentifier = [self tappedViewforGestureRecognizer:recognizer];
    
    if (recognizer.state == UIGestureRecognizerStateBegan && tappedViewIdentifier == MINUSBUTTON_TAP)
        [self handleTallyReset:recognizer];

    
    if (recognizer.state == UIGestureRecognizerStateBegan && tappedViewIdentifier == TITLE_TAP)
        [self editTrivitTitleAtIndexPath:indexPath];
}

-(void) editTrivitTitleAtIndexPath: (NSIndexPath *) indexPath{
    if (!indexPath)
        indexPath = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0]-1 inSection:0];
    
    if(self.cellBeingEdited)
        self.cellBeingEdited.titleTextField.enabled = NO;
    
    TrivitTableViewCell *tappedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    tappedCell.loadAnimation = NO;
    self.cellBeingEdited = tappedCell; //Save cell being edited
    self.activeCellIndexPath = indexPath;     //save indexPath to show after keyboard hides
    tappedCell.titleTextField.enabled = YES;
    [tappedCell.titleTextField becomeFirstResponder];
    [tappedCell.titleTextField selectAll: nil];
}

#pragma mark - cell height calculation

-(float) cellHeigthForTallyCount: (NSInteger) tallyCount // values are based on trial and error
{
    float tally_image_Count = ceil(tallyCount / 5.);
    
    int rows = ceil(1.*tally_image_Count/self.imagesPerRow);
    if (rows <2)
        return CELL_HEIGHT_SECTION1+TALLY_IMAGE_DIMENSION;
    else
        return CELL_HEIGHT_SECTION1 + rows*(TALLY_IMAGE_DIMENSION+COLLECTIONVIEW_VERTICAL_SPACING);
}

#pragma mark - Magic to make the tableview datasource working

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.view.userInteractionEnabled = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (![record.isCollapsed boolValue])
        return MAX(CELL_HEIGHT_SECTION1 + CELL_HEIGHT_SECTION2,CELL_HEIGHT_SECTION1+[self cellHeigthForTallyCount:[record.counter integerValue]]); // Full
    else
        return CELL_HEIGHT_SECTION1; // Only first section of the cell (title UILabel) (if cell is not selected... seems always to be the case
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TrivitTableViewCell *cell = [[TrivitTableViewCell alloc] init];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(TrivitTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Fetch Record
    
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Update Cell
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.appSettings = self.appSettings;
    bool isCollapsed = [record.isCollapsed boolValue];
    if (cell.isCollapsed!=isCollapsed)
        cell.isCollapsed = isCollapsed;
    cell.tally.counter = [record.counter integerValue];
    cell.tally.colorIndex = [record.color integerValue];
    cell.tally.title = record.title;
    cell.tally.type = record.type;
    
    cell.cellIdentifier = (int)indexPath.row;
    if (!cell.titleTextField.delegate)
        cell.titleTextField.delegate = self;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

// remove logic
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // row can be deleted if tally is collapsed
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    return [record.isCollapsed boolValue]&&!self.keyboardShown;
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
    if(self.shouldScrollToCellAtIndexPath)
        [self.tableView scrollToRowAtIndexPath:self.shouldScrollToCellAtIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    // on next GUI update, do not scroll anymore
    self.shouldScrollToCellAtIndexPath=nil;
}

-(void) scrollToExpandedCell: (NSIndexPath *)indexPath
{
    NSArray *visibleRows = [self.tableView visibleCells];
    
    // get last cell visible in the current view
    TrivitTableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *lastIndexPath = [self.tableView indexPathForCell:lastVisibleCell];
    
    self.shouldScrollToCellAtIndexPath = nil;
    switch (lastIndexPath.row-indexPath.row) {
        case 0:
            self.shouldScrollToCellAtIndexPath = indexPath;
            break;
        case 1:
            if(lastVisibleCell.isCollapsed && !self.shouldScrollOnTallyIncreaseOrDecrease)
                self.shouldScrollToCellAtIndexPath = indexPath;
            break;
        case 2:
        {
            TrivitTableViewCell *oneButLastVisibleCell = [[visibleRows subarrayWithRange:NSMakeRange(([visibleRows count]-2), 1)] firstObject];
            if(lastVisibleCell.isCollapsed && oneButLastVisibleCell.isCollapsed && !self.shouldScrollOnTallyIncreaseOrDecrease)
                self.shouldScrollToCellAtIndexPath = indexPath;
            break;
        }
        default:
            break;
    }
    self.shouldScrollOnTallyIncreaseOrDecrease=false;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(TrivitTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

-(void) orientationChanged: (NSNotification *)notification
{
    for (TrivitTableViewCell *cell in [self.tableView visibleCells]) {
        if (!cell.isCollapsed)
            cell.reloadCompleteCell=true;
    }
}

#pragma mark - view load stuff

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureTableView];
    
    // load Settings from NSUserDefaults
    self.defaults = [NSUserDefaults standardUserDefaults];
    
    // Initialize Fetch Request
    self.fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TallyModel"];
    
    // Add Sort Descriptors
    [self.fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    // Configure Fetched Results Controller
    [self.fetchedResultsController setDelegate:self];
    
    // Perform Fetch
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    
    if (![[self.defaults objectForKey:@"tutorialShown"] boolValue]){
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UINavigationController *tutorialVC = (UINavigationController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"tutorialMasterViewController"];
        [self presentViewController:tutorialVC animated:YES completion:^{}];
        // if empty: add some trivits
        if (self.trivitCount == 0){
            [self addItemWithTitle:NSLocalizedString(@"Drinks",@"Tally example")];
            [self addItemWithTitle:NSLocalizedString(@"Days without smoking", @"Tally example") andCount:550];
            [self addItemWithTitle:NSLocalizedString(@"Went swimming this year", @"Tally example") andCount:44];
        }
    }
    else
    {
        self.appSettings.vibrationFeedback = [[self.defaults objectForKey:@"vibrationFeedback"] boolValue];
        self.appSettings.selectedColorSet = [[self.defaults objectForKey:@"selectedColorSet"] integerValue];
    }
    
    // subscribe to notifications for keyboard show and hide, used for changing view size
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    // subscribe to device rotation
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void) configureTableView{
    // add gestures
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    UILongPressGestureRecognizer * longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longTap.minimumPressDuration = 0.2;
    
    [self.tableView addGestureRecognizer:tap];
    [self.tableView addGestureRecognizer:longTap];
    
    // add background
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableViewBackgroundTally"]];
    imageView.contentMode = UIViewContentModeCenter; // don't allow rescaling of the image
    self.tableView.backgroundColor = [Colors colorWithHexString:@"F5F4F4"];
    self.tableView.backgroundView = imageView; // add UIImageView to the tableView background
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.cellBeingEdited = nil;
    if ([segue.identifier isEqualToString:@"ShowSettingsForTrivit"])
    {
        if ([segue.destinationViewController isKindOfClass:[SettingsViewController class]])
        {
            SettingsViewController *svc = (SettingsViewController *) segue.destinationViewController;
            svc.appSettings = self.appSettings;
            [svc setManagedObjectContext:self.managedObjectContext];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    // reload data in case the color would have changed
    // TODO: check if appSettings.selectedColorSet has changed and only refresh if it is true
    // we should make a NSNumber number with boolean and pass it in the prepareforsegue (nsnumber is passed by reference)
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

#pragma mark - view resize on keyboard show

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    self.keyboardShown = true;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, kbSize.height, self.tableView.contentInset.right);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    TrivitTableViewCell *activeCell = (TrivitTableViewCell *) [self.tableView cellForRowAtIndexPath:self.activeCellIndexPath];
    
    if (!CGRectContainsPoint(aRect, activeCell.frame.origin) )
        [self.tableView scrollRectToVisible:activeCell.frame animated:YES];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    TallyModel *record = [self.fetchedResultsController objectAtIndexPath:self.activeCellIndexPath];
    
    //Set dev device or not
    if([self.cellBeingEdited.titleTextField.text isEqualToString:@"ThisIsADevDevice"])
        [self.defaults setObject:[NSNumber numberWithBool:true] forKey:@"DevDevice"];
    
    else if([self.cellBeingEdited.titleTextField.text isEqualToString:@"ThisIsNoDevDeviceNoMore"])
        [self.defaults setObject:[NSNumber numberWithBool:false] forKey:@"DevDevice"];
    
    if (self.cellBeingEdited.titleTextField != nil){
        record.title = self.cellBeingEdited.titleTextField.text;
        NSString *tallyType = (self.cellBeingEdited.titleTextField.text.length>0)&&[[self.cellBeingEdited.titleTextField.text substringToIndex:1] isEqual: @"_"]?@"ch_":@"";
        record.type = tallyType;
    }
    
    self.cellBeingEdited.titleTextField.enabled = NO;
    self.activeCellIndexPath = nil;
    self.cellBeingEdited = nil;
    
    // restore the insets
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 0, self.tableView.contentInset.right);

    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    //keyboard is no longer shown
    self.keyboardShown=false;
    self.trivitRecentlyAdded=false;
}

// Do not hide status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

@end
