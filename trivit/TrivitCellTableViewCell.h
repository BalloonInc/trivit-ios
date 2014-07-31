//
//  TrivitCellTableViewCell.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Counter.h"
#import "TrivitCollectionViewCell.h"

@interface TrivitCellTableViewCell : UITableViewCell <UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>

extern float const CELL_HEIGHT_SECTION1;
extern float const CELL_HEIGHT_SECTION2;

@property (strong, nonatomic) Counter *counter;
@property (strong, nonatomic) NSString *counterString;
@property (nonatomic) int cellIdentifier;
@property (nonatomic) BOOL isCollapsed;
@property (nonatomic,strong) UIColor *cellBackColor;
@property (nonatomic,strong) UIColor *cellBackColorDark;
@property (nonatomic,strong) UIImageView *modImage;
@property (nonatomic,strong) UICollectionView *images;

@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) UILabel *counterLabelForTally;
@property (strong, nonatomic) UILabel *countLabel;

//@property (strong, nonatomic) IBOutlet UITextField *titleLabelTextField;

//colorset_func
//@property (nonatomic,strong) NSArray *colorset;

- (void)decreaseTallyCounter;
- (void)increaseTallyCounter;
- (void)resetTallyCounter;
//colorset_func
//- (void) resetColor;

@end
