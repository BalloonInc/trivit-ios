//
//  MainListViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "MainListViewController.h"
#import "TrivitCellTableViewCell.h"
#import "settingsViewController.h"
#import "Colors.h"

@interface MainListViewController ()
@property (strong, nonatomic) TrivitCellTableViewCell *firstCell;
@end

@implementation MainListViewController

#pragma mark - lazy instantiatiors
-(NSMutableArray*) tallies{
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
    // add random identifier to tallies
    [self addItemWithTitle:[NSString stringWithFormat:@"newTally_%lu",(unsigned long)[self.tallies count]]];
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
    TrivitCellTableViewCell *newCell = [[TrivitCellTableViewCell alloc] init];
    newCell.counter.title = title;
    newCell.counter.countForTally = count;
    [self.tallies addObject:newCell];
    
    [self.tableView reloadData];
}

# pragma mark - selectors for gestures

-(void) handleTallyReset: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    if(!swipedCell.isCollapsed)
        [swipedCell resetTallyCounter];
    
}

-(void) handleTallyIncrease: (UIGestureRecognizer *)recognizer
{
    NSLog(@"handleTallyIncrease");
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    if(!swipedCell.isCollapsed)
        [swipedCell increaseTallyCounter];
    
}

-(void) handleTallyDecrease: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    if(!swipedCell.isCollapsed)
        [swipedCell decreaseTallyCounter];
    
}

-(void) handleTallyCollapse: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    swipedCell.isCollapsed = ! swipedCell.isCollapsed;
}

-(void)handleTap: (UIGestureRecognizer *)recognizer
{
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    TrivitCellTableViewCell *tappedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    UIView *tappedView = [self.tableView hitTest:tapLocation withEvent:nil];
    if (tappedView==tappedCell.titleLabelForTally){
        [self handleTallyCollapse:recognizer];
    }
    else if(tappedView==tappedCell.counterLabelForTally){
        [self handleTallyIncrease:recognizer];
    }
    else{
        NSLog(@"You tapped on a very weird spot");
    }
}

#pragma mark - Magic to make the tableview datasource working

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    TrivitCellTableViewCell *cell = (TrivitCellTableViewCell*)self.tallies[indexPath.row];
    if (cell.isCollapsed) {
        return 84.0f; // Full height
    }
    else {
//        return 30.0f; // Only first section of the cell (title UILabel) (if cell is not selected... seems always to be the case
        return 84.0f;
    }
    
}

- (void)addOrRemoveSelectedIndexPath:(NSIndexPath *)indexPath
{
    if (!self.selectedTallies) {
        self.selectedTallies = [NSMutableArray new];
    }
    
    BOOL containsIndexPath = [self.selectedTallies containsObject:indexPath];
    
    if (containsIndexPath) {
        [self.selectedTallies removeObject:indexPath];
    }else{
        [self.selectedTallies addObject:indexPath];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self addOrRemoveSelectedIndexPath:indexPath];
    
}

/*
 *   the cellForRowAtIndexPath takes for argument the tableView (so if the same object
 *   is delegate for several tableViews it can identify which one is asking for a cell),
 *   and an idexPath which determines which row and section the cell is returned for.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     *   This is an important bit, it asks the table view if it has any available cells
     *   already created which it is not using (if they are offscreen), so that it can
     *   reuse them (saving the time of alloc/init/load from xib a new cell ).
     *   The identifier is there to differentiate between different types of cells
     *   (you can display different types of cells in the same table view)
     */
    
    NSString *CellIdentifier = [NSString stringWithFormat: @"trivitCell_%ld", (long)indexPath.row];
    
    TrivitCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    /*
     *   If the cell is nil it means no cell was available for reuse and that we should
     *   create a new one.
     */
    if (cell == nil) {
        /*
         *   Actually create a new cell (with an identifier so that it can be dequeued).
         */
        cell = [[TrivitCellTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        NSLog(CellIdentifier,nil);
        cell.isCollapsed = true;
        cell.counter.countForTally = [[self.tallies[indexPath.row] counter] countForTally];
        cell.counter.title = [[self.tallies[indexPath.row] counter] title];
        cell.cellIdentifier = (int)indexPath.row;
        //colorset_func
        //cell.colorset = [Colors colorsetWithIndex:self.appSettings.colorSet];

    }
    else{
        NSLog(@"%@ existed!",CellIdentifier);
        NSLog(@"%i",self.selectedTallies.count);
    }
    
    
    /* Now that the cell is configured we return it to the table view so that it can display it */
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    // If You have only one(1) section, return 1, otherwise you must handle sections
    return 1;
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
    // add test tally
    [self addItemWithTitle:@"testTally"];
    
}

- (void) configureTableView{
    // add gestures
    UISwipeGestureRecognizer * rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyReset:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    UISwipeGestureRecognizer * leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyDecrease:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    [self.tableView addGestureRecognizer:rightSwipe];
    [self.tableView addGestureRecognizer:leftSwipe];
    [self.tableView addGestureRecognizer:tap];

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
    //hide navigation bar
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    //colorset_func
    //[self resetColors];
    [super viewWillAppear:animated];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    //show navigation bar when segueing for a smooth transition
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

#pragma mark - more functions
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
