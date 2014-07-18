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
@synthesize tableView = _tableView;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tallies = [NSMutableArray new];
    self.firstCell = [[TrivitCellTableViewCell alloc] init];
    self.firstCell.counter.title = @"testTally";
    
    [self.tallies addObject:self.firstCell];
    [self.tableView reloadData];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    _tableView.delegate=self; // I had to use _NAME, even if I synthesized this variable.
    _tableView.dataSource=self;
    [super viewWillAppear:YES];
}

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
