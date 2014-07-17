//
//  TrivitCellTableViewCell.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Counter.h"

@interface TrivitCellTableViewCell : UITableViewCell
@property (strong, nonatomic) Counter *counter;
@property (nonatomic) BOOL isCollapsed;
@end
