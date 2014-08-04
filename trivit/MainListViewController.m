//
//  MainListViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "MainListViewController.h"
#import "TrivitTableViewCell.h"
#import "settingsViewController.h"
#import "Colors.h"

@interface MainListViewController ()
@property (strong, nonatomic) TrivitTableViewCell *firstCell;
@end

@implementation MainListViewController

#pragma mark - lazy instantiatiors

-(NSMutableArray*) expandedTrivits
{
    if(!_expandedTrivits){_expandedTrivits = [[NSMutableArray alloc] init];}
    return _expandedTrivits;
}

-(NSMutableArray*) tallies
{
    if(!_tallies){_tallies=[[NSMutableArray alloc ]init];}
    return _tallies;
}

@synthesize appSettings=_appSettings;

-(Settings*) appSettings{
    if(!_appSettings){_appSettings=[[Settings alloc ]init];}
    return _appSettings;
}

-(void) setAppSettings:(Settings *)appSettings
{
    _appSettings=appSettings;
}


#pragma mark - add item

-(IBAction) addButtonPressed
{
    // add consequent identifier to tallies
    [self addItemWithTitle:[NSString stringWithFormat:@"newTally_%lu",(unsigned long)[self.tallies count]]];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.tallies.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    Tally *newTally = [[Tally alloc] init];
    newTally.title = title;
    newTally.counter = count;
    newTally.isCollapsed=true;
    
    [self.tallies addObject:newTally];
    
    [self.tableView reloadData];
}


# pragma mark - selectors for gestures

-(void) handleTallyReset: (UIGestureRecognizer *)leftSwipeRecognizer
{
    // if a cell title is being edited don't process taps
    if (self.cellBeingEdited)
        return;

    CGPoint swipeLocation = [leftSwipeRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *swipedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    if(!swipedCell.isCollapsed){
        [swipedCell resetTallyCounter];
        [self.tallies[swipedIndexPath.row] setCounter:0];

        [self.tableView beginUpdates]; // necessary for the animation of the cell growth
        [self.tableView endUpdates]; // necessary for the animation of the cell growth
    }
    
}

-(void) handleTallyIncrease: (UIGestureRecognizer *)singletapRecognizer
{
    CGPoint swipeLocation = [singletapRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *increasedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    if(!increasedCell.isCollapsed){
        [increasedCell increaseTallyCounter];
        [self.tallies[swipedIndexPath.row] setCounter:[self.tallies[swipedIndexPath.row] counter]+1];
        
        // if new image ==> redraw cell height
        if ([self.tallies[swipedIndexPath.row] counter]%5==1){
        [self.tableView beginUpdates]; // necessary for the animation of the cell growth
        [self.tableView endUpdates]; // necessary for the animation of the cell growth
        }
    }
}

-(void) handleTallyDecrease: (UIGestureRecognizer *)leftSwipeRecognizer
{
    // if a cell title is being edited don't process taps
    if (self.cellBeingEdited)
        return;

    CGPoint swipeLocation = [leftSwipeRecognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *swipedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    if(!swipedCell.isCollapsed){
        [swipedCell decreaseTallyCounter];
        [self.tallies[swipedIndexPath.row] setCounter:[self.tallies[swipedIndexPath.row] counter]-1];
        // if image got removed ==> redraw cell height
        if ([self.tallies[swipedIndexPath.row] counter]%5==0){
            [self.tableView beginUpdates]; // necessary for the animation of the cell growth
            [self.tableView endUpdates]; // necessary for the animation of the cell growth
        }

    }
    
}

-(void) handleTallyCollapse: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *collapseIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitTableViewCell *collapseCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:collapseIndexPath];
    
    collapseCell.isCollapsed = !collapseCell.isCollapsed;
    [self.tallies[collapseIndexPath.row] setIsCollapsed:collapseCell.isCollapsed];

    collapseCell.loadAnimation = YES;
    if (!collapseCell.isCollapsed){
        [self.expandedTrivits addObject:collapseIndexPath];
        //[self.tableView scrollToRowAtIndexPath:collapseIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tallies count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];

    }
    else{
        [self.expandedTrivits removeObject:collapseIndexPath];
    }
    [self.tableView beginUpdates]; // necessary for the animation of the tableViewCell
    [self.tableView endUpdates]; // necessary for the animation of the tableViewCell

}

-(void)handleTap: (UIGestureRecognizer *)singletapRecognizer
{
    // if a cell title is being edited don't process taps
    if (self.cellBeingEdited)
        return;
    
    CGPoint tapLocation = [singletapRecognizer locationInView:self.tableView];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    TrivitTableViewCell *tappedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:tappedIndexPath];
    UIView *tappedView = [self.tableView hitTest:tapLocation withEvent:nil];
    
    if(tappedView==tappedCell.counterLabelForTally){
        [self handleTallyIncrease:singletapRecognizer];
    }
    
    else if (CGRectContainsPoint(tappedCell.frame, tapLocation)){
        [self handleTallyCollapse:singletapRecognizer];
        
    }
    else{
        NSLog(@"You tapped on a very weird spot");
        //[self handleTallyCollapse:recognizer];
        
    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer * )recognizer
{
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long press on tableview at row %tu", indexPath.row);
        TrivitTableViewCell *tappedCell = (TrivitTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        
        if (self.cellBeingEdited)
            self.cellBeingEdited.titleTextField.enabled=NO; // disable previous editing
        self.cellBeingEdited = tappedCell; //Save cell being edited
        
        self.activeCellIndexPath = indexPath;     //save indexPath to show after keyboard hides
        
        // only disappear using the LongPress gesture, reappearing is handled by end of editing
        tappedCell.titleTextField.enabled = YES;
        [tappedCell.titleTextField becomeFirstResponder];
    }
}

#pragma mark - cell height calculation

-(float) cellHeigthForTallyCount: (int) tallyCount // values are based on trial and error
{
    tallyCount = (int) ceil((tallyCount / 5.));
    float divisor = self.view.frame.size.width / 34.;
    int rows = ceil(tallyCount/divisor);
    return CELL_HEIGHT_SECTION1 + rows*34;
}


#pragma mark - Magic to make the tableview datasource working

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.view.userInteractionEnabled = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    
    if ([self.expandedTrivits containsObject:indexPath]) {
        Tally *tally = [self.tallies objectAtIndex: indexPath.row];
        NSLog(@"count: %tu",tally.counter);
        NSLog(@"numbder of tallies: %tu", self.tallies.count);
        return MAX(CELL_HEIGHT_SECTION1 + CELL_HEIGHT_SECTION2,CELL_HEIGHT_SECTION1+[self cellHeigthForTallyCount:tally.counter]); // Full
    }
    else {
        return CELL_HEIGHT_SECTION1; // Only first section of the cell (title UILabel) (if cell is not selected... seems always to be the case
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat: @"trivitCell_%ld", (long)indexPath.row];
  
    TrivitTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //TrivitTableViewCell *cell = nil;

    if (cell == nil) {
        cell = [[TrivitTableViewCell alloc] init];
        //cell = [[TrivitTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.isCollapsed = [self.tallies[indexPath.row] isCollapsed];
        cell.tally.counter = [self.tallies[indexPath.row] counter];
        NSLog(@"cell count in cellForRowAtIndexPath: %d", cell.tally.counter);
        cell.tally.title = [self.tallies[indexPath.row] title];
        NSLog(@"cell title in cellForRowAtIndexPath %@", cell.tally.title);

        cell.cellIdentifier = (int)indexPath.row;
        cell.titleTextField.delegate = self;
        //colorset_func
        //cell.colorset = [Colors colorsetWithIndex:self.appSettings.colorSet];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.tallies count];
}


#pragma mark - view load stuff

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureTableView];
    
    [self addItemWithTitle:@"Drinks"];
    [self addItemWithTitle:@"Days without smoking" andCount:110];
    [self addItemWithTitle:@"Went swimming this year" andCount:44];
    
    // subscribe to notifications for keyboard show and hide, used for changing view size
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
}

- (void) configureTableView{
    // add gestures
    UISwipeGestureRecognizer * rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyReset:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    UISwipeGestureRecognizer * leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyDecrease:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    UILongPressGestureRecognizer * longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longTap.minimumPressDuration = 0.5;
    
    [self.tableView addGestureRecognizer:rightSwipe];
    [self.tableView addGestureRecognizer:leftSwipe];
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
    if ([segue.identifier isEqualToString:@"ShowSettingsForTrivit"])
    {
        if ([segue.destinationViewController isKindOfClass:[settingsViewController class]])
        {
            settingsViewController *svc = (settingsViewController *) segue.destinationViewController;
            svc.appSettings = self.appSettings;
            
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    //colorset_func
    //[self resetColors];
    [super viewWillAppear:animated];
}


#pragma mark - settings

//colorset_func
/*
 -(void) resetColors
 {
 for (TrivitCellTableViewCell* cell in self.tallies) {
 cell.colorset = [Colors colorsetWithIndex:self.appSettings.colorSet];
 [cell resetColor];
 }
 }
 */


#pragma mark - view resize on keyboard show

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if(self.keyboardShown)
        return;
    
    self.keyboardShown = YES;
    
    // Get the keyboard size
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    // Get the keyboard's animation details
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    self.keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if(self.inputAccessoryView && self.keyboardOverlap>0)
    {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        self.keyboardOverlap -= accessoryHeight;
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }
    
    if(self.keyboardOverlap < 0)
        self.keyboardOverlap = 0;
    
    if(self.keyboardOverlap != 0)
    {
        tableFrame.size.height -= self.keyboardOverlap;
        
        NSTimeInterval delay = 0;
        if(keyboardRect.size.height)
        {
            delay = (1 - self.keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * self.keyboardOverlap/keyboardRect.size.height;
        }
        
        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ tableView.frame = tableFrame; }
                         completion:^(BOOL finished){ [self tableAnimationEnded:nil finished:nil contextInfo:nil]; }];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    self.cellBeingEdited = nil;
    if(!self.keyboardShown)
        return;
    
    self.keyboardShown = NO;
    
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    if(self.inputAccessoryView)
    {
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    
    if(self.keyboardOverlap == 0)
        return;
    
    // Get the size & animation details of the keyboard
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    CGRect tableFrame = tableView.frame;
    tableFrame.size.height += self.keyboardOverlap;
    
    if(keyboardRect.size.height)
        animationDuration = animationDuration * self.keyboardOverlap/keyboardRect.size.height;
    
    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ tableView.frame = tableFrame; }
                     completion:nil];
}

- (void) tableAnimationEnded:(NSString*)animationID finished:(NSNumber *)finished contextInfo:(void *)context
{
    // Scroll to the active cell
    if(self.activeCellIndexPath)
    {
        [self.tableView scrollToRowAtIndexPath:self.activeCellIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        [self.tableView selectRowAtIndexPath:self.activeCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    self.activeCellIndexPath = nil;
}


#pragma mark - Core Data

#pragma mark -


@end
