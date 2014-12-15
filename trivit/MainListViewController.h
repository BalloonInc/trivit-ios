//
//  MainListViewController.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "TrivitTableViewCell.h"

@interface MainListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) TrivitTableViewCell *cellBeingEdited;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Settings *appSettings;

// is keyboard shown or not
@property (nonatomic) bool keyboardShown;

@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) UIEdgeInsets scrollIndicatorInsets;

// used when changing title, cell should be in view when view resizes
@property (nonatomic, strong) NSIndexPath *activeCellIndexPath;

// Core Data
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSUserDefaults *defaults;
@end