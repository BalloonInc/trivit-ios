//
//  MainListViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "MainListViewController.h"
#import "TrivitCellTableViewCell.h"

@interface MainListViewController ()
@property (strong, nonatomic) TrivitCellTableViewCell *firstCell;
@end

@implementation MainListViewController


# pragma mark - Loading

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
    // Double tap to open/close: not really convenient
    //UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyCollapse:)];
    //doubleTap.numberOfTapsRequired=2;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyCollapse:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyIncrease:)];

    [self.tableView addGestureRecognizer:rightSwipe];
    [self.tableView addGestureRecognizer:leftSwipe];
    //[self.tableView addGestureRecognizer:doubleTap];
    [self.tableView addGestureRecognizer:longPress];
    [self.tableView addGestureRecognizer:tap];
}

-(NSMutableArray*) tallies{
    
    if(!_tallies){_tallies=[[NSMutableArray alloc ]init];}
    return _tallies;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [super viewWillAppear:animated];
}

#pragma mark - add item

-(IBAction) addButtonPressed
{
    [self addItem];
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
    if (recognizer.state == UIGestureRecognizerStateBegan) {
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    swipedCell.isCollapsed = ! swipedCell.isCollapsed;
    }
    
}

#pragma mark - Magic to make the tableview datasource working

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
    static NSString *CellIdentifier = @"trivitCell";
    
    TrivitCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    /*
     *   If the cell is nil it means no cell was available for reuse and that we should
     *   create a new one.
     */
    if (cell == nil) {
        /*
         *   Actually create a new cell (with an identifier so that it can be dequeued).
         */
        //cell = [[TrivitCellTableViewCell alloc] init];
        cell = [[TrivitCellTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"trivitCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.isCollapsed = true;
    }
    
    cell.counter.countForTally = [[self.tallies[indexPath.row] counter] countForTally];
    cell.counter.title = [[self.tallies[indexPath.row] counter] title];
    
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
