//
//  MainListViewController.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"

@interface MainListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *tallies; // of TrivitCellTableViewCell
@property (strong, nonatomic) NSMutableArray *selectedTallies; // of TrivitCellTableViewCell
@property (strong, nonatomic) Settings *appSettings;
@property (strong, nonatomic) NSMutableArray *expandedTrivits; // of NSIndexPath
//@property (nonatomic, strong) NSMutableArray *selectedIndexPaths;

@end
