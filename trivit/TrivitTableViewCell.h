//
//  TrivitCellTableViewCell.h
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Tally.h"
#import <UIKit/UIKit.h>
@class MainListViewController;
#import "Settings.h"

@interface TrivitTableViewCell : UITableViewCell <UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>

extern float const CELL_HEIGHT_SECTION1;
extern float const CELL_HEIGHT_SECTION2;
extern float const TALLY_IMAGE_DIMENSION;
extern float const COLLECTIONVIEW_VERTICAL_INSET;
extern float const COLLECTIONVIEW_HORIZONTAL_INSET;
extern float const COLLECTIONVIEW_VERTICAL_SPACING;
extern float const COLLECTIONVIEW_HORIZONTAL_SPACING;
extern NSString const *TALLY_TYPE;

@property(nonatomic, strong) Tally *tally;
@property(nonatomic) int cellIdentifier;
@property(nonatomic) BOOL isCollapsed;
@property(strong, nonatomic) Settings *appSettings;
@property(nonatomic, strong) UIColor *cellBackColor;
@property(nonatomic, strong) UIColor *cellBackColorDark;

@property(nonatomic, strong) UICollectionView *images;
@property(nonatomic) BOOL loadAnimation;
@property(nonatomic) BOOL reloadCompleteCell;
@property(nonatomic) BOOL cellWillRotate;

@property(strong, nonatomic) UIView *backgroundViewForTitle;
@property(strong, nonatomic) UITextField *titleTextField;
@property(strong, nonatomic) UILabel *tallyImageZone;
@property(strong, nonatomic) UILabel *countLabel;
@property(strong, nonatomic) UITextField *minusButton;
@property(nonatomic) float cellHeigth;

@property(weak, nonatomic) MainListViewController *parentViewController;


- (void)decreaseTallyCounter;
- (void)increaseTallyCounter;
- (void)showTalliesWithDelay;
- (void) flashTrivit;
- (void) flashIncrement;


@end