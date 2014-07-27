//
//  MainListViewController.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *tallies; // of TrivitCellTableViewCell
@property (strong, nonatomic) NSMutableArray *selectedTallies; // of TrivitCellTableViewCell
//@property (nonatomic, strong) NSMutableArray *selectedIndexPaths;

@end
