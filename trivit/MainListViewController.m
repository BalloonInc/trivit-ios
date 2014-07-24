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
    UISwipeGestureRecognizer * leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTallyDecrease:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTitleTap:)];
    
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [self.tableView addGestureRecognizer:leftSwipe];
    [self.tableView addGestureRecognizer:rightSwipe];
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
    [swipedCell resetTallyCounter];
    
}

-(void) handleTallyIncrease: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    [swipedCell increaseTallyCounter];
    
}

-(void) handleTallyDecrease: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    [swipedCell decreaseTallyCounter];
    
}

-(void) handleTitleTap: (UIGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    TrivitCellTableViewCell *swipedCell = (TrivitCellTableViewCell*)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
    swipedCell.isCollapsed = ! swipedCell.isCollapsed;
    
}

#pragma mark - Magic to make the tableview datasource working

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    TrivitCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TrivitCellTableViewCell alloc] init];
        cell.isCollapsed = true;
    }
    
    // Configure the cell...
    cell.counter.countForTally = [[self.tallies[indexPath.row] counter] countForTally];
    cell.counter.title = [[self.tallies[indexPath.row] counter] title];
    
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
