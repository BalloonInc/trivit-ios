//
//  TrivitCellTableViewCell.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tally.h"
#import "TrivitCollectionViewCell.h"
#import "PaddingUITextField.h"

@interface TrivitTableViewCell : UITableViewCell <UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>

extern float const CELL_HEIGHT_SECTION1;
extern float const CELL_HEIGHT_SECTION2;
extern NSString const *TALLY_TYPE;

@property (strong, nonatomic) Tally *tally;
@property (strong, nonatomic) NSString *counterString;
@property (nonatomic) int cellIdentifier;
@property (nonatomic) BOOL isCollapsed;
@property (nonatomic,strong) UIColor *cellBackColor;
@property (nonatomic,strong) UIColor *cellBackColorDark;
@property (nonatomic,strong) UIImageView *modImage;
@property (nonatomic,strong) UICollectionView *images;
@property (nonatomic) BOOL loadAnimation;

@property (strong, nonatomic) PaddingUITextField *titleTextField;
@property (strong, nonatomic) UILabel *counterLabelForTally;
@property (strong, nonatomic) UILabel *countLabel;


@property (nonatomic) float cellHeigth;

//colorset_func
//@property (nonatomic,strong) NSArray *colorset;

- (void)decreaseTallyCounter;
- (void)increaseTallyCounter;
- (void)resetTallyCounter;

- (void) onLoadAnimation;

//colorset_func
//- (void) resetColor;

@end
