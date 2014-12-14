//
//  TrivitCellTableViewCell.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TrivitTableViewCell.h"
#import "Colors.h"

@interface TrivitTableViewCell()
@property int cellAddRemove;
@end

@implementation TrivitTableViewCell

#pragma mark - Constants
float const CELL_HEIGHT_SECTION1 = 44.0;
float const CELL_HEIGHT_SECTION2 = 88.0;
float const TALLY_IMAGE_DIMENSION = 32.;
float const COLLECTIONVIEW_HORIZONTAL_SPACING = 15.;
float const COLLECTIONVIEW_VERTICAL_SPACING = 5.;
float const COUNTLABEL_HEIGHT = 30.;
float const COUNTLABEL_WIDTH = 40.;

#pragma mark - update tally functions

- (void)increaseTallyCounter
{
    [self.tally addTally];
    self.cellAddRemove = (self.tally.counter%5==1)?1:0; // if new cell should be drawn: 1
    [self setNeedsDisplay];
}

- (void)decreaseTallyCounter
{
    [self.tally decreaseTally];
    self.cellAddRemove = (self.tally.counter%5==0)?-1:0; // if last cell should be removed: -1
    [self setNeedsDisplay];
}

#pragma mark - lazy instantiators

-(void) setIsCollapsed:(BOOL)isCollapsed
{
    _isCollapsed = isCollapsed;
    [self setNeedsDisplay];
}

-(UIColor*)cellBackColor
{
    if (!_cellBackColor){
        _cellBackColor=[Colors colorWithIndex:self.tally.colorIndex usingColorSet: [Colors colorsetWithIndex:self.appSettings.selectedColorSet*2]];
    }
    return _cellBackColor;
}

-(UIColor*)cellBackColorDark
{
    if (!_cellBackColorDark){
        _cellBackColorDark = [Colors colorWithIndex:self.tally.colorIndex usingColorSet: [Colors colorsetWithIndex:self.appSettings.selectedColorSet*2+1]];
    }
    return _cellBackColorDark;
}

-(Tally*)tally
{
    if (!_tally){_tally = [[Tally alloc] init];}
    return _tally;
}

- (void) configureCountLabelWithInteger:(int) integer forCollapsedTrivit:(BOOL)collapsed
{
    if (collapsed){
        //TODO: can be removed?
        self.countLabel=nil;
        if (!self.countLabel){
            self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, COUNTLABEL_WIDTH, COUNTLABEL_HEIGHT)];
            self.countLabel.backgroundColor = self.cellBackColorDark;
            self.countLabel.textAlignment = 1;
            self.countLabel.textColor = [UIColor whiteColor];
            [self.countLabel.layer setCornerRadius:8.0];
            [self.countLabel.layer setMasksToBounds:YES];
        }
        self.countLabel.text = @(integer).stringValue;
        
        //Animation only if loadanimation is set (e.g. when expanding)
        if (self.loadAnimation){
            self.countLabel.alpha = 0;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:1.3];
            [UIView setAnimationDelegate:self];
            self.countLabel.alpha = 1.0;
            [UIView commitAnimations];
        }
        
        [self setAccessoryView:self.countLabel];
    }
    else{
        //TODO: can be removed?
        self.minusButton=nil;

        if(!self.minusButton){
            self.minusButton = [[UITextField alloc] initWithFrame:CGRectMake(0,0, COUNTLABEL_WIDTH, COUNTLABEL_HEIGHT)];
            self.minusButton.backgroundColor = [UIColor whiteColor];

            self.minusButton.textAlignment = NSTextAlignmentCenter;
            [self.minusButton.layer setCornerRadius:8.0];
            [self.minusButton.layer setMasksToBounds:YES];

            // Don't touch this minus sign + font below, or spend half a day trying to center it vertically again
            self.minusButton.font = [UIFont fontWithName:@"Georgia-Italic" size:25];
            
            self.minusButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            
            self.minusButton.textColor = self.cellBackColorDark;
            self.minusButton.enabled=NO;
            self.minusButton.text = @"−";
    }
        
        //Animation only if loadanimation is set (e.g. when expanding)
        if (self.loadAnimation){
            self.minusButton.alpha = 0;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:1.3];
            [UIView setAnimationDelegate:self];
            self.minusButton.alpha = 1.0;
            [UIView commitAnimations];
        }
        [self setAccessoryView:self.minusButton];
        
    }
}

- (void)drawRect:(CGRect)rect
{
    [self.titleTextField removeFromSuperview];
    [self.counterLabelForTally removeFromSuperview];
    [self.countLabel removeFromSuperview];
    //[self.images removeFromSuperview];
    
    // first section
    UIBezierPath *recta = [UIBezierPath bezierPathWithRect:self.bounds];
    [recta addClip];
    
    [[self cellBackColor] setFill];
    [recta fill];
    
    // only re-add if it is not yet there
    if (![self.subviews containsObject:self.titleTextField])
    {
        CGRect boundsTitleLabel = CGRectMake(0, 0, self.frame.size.width, CELL_HEIGHT_SECTION1);
        self.titleTextField = [[PaddingUITextField alloc] initWithFrame:boundsTitleLabel];
        self.titleTextField.textColor = [UIColor whiteColor]; // whiteColor text
        self.titleTextField.userInteractionEnabled = true;
        self.titleTextField.backgroundColor = self.cellBackColor;
        self.titleTextField.enabled = NO;
        self.titleTextField.returnKeyType = UIReturnKeyDone;
        self.titleTextField.keyboardType = UIKeyboardAppearanceDefault;
        self.titleTextField.tintColor = [UIColor lightTextColor]; // white Carret
        self.titleTextField.delegate = self;
        self.titleTextField.gestureRecognizers = nil;
        
        [self addSubview: self.titleTextField];
    }
    // update title
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.firstLineHeadIndent = 10;
    //if (self.tally.title == nil)
      //  self.tally.title = @"";
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:self.tally.title attributes:@{NSParagraphStyleAttributeName: paragraphStyle}];
    self.titleTextField.attributedText = attributedTitle;
    
    
    [self configureCountLabelWithInteger:(int)self.tally.counter forCollapsedTrivit:self.isCollapsed];
    if (self.isCollapsed)
        [self.images removeFromSuperview];
    
    else{
        CGRect boundsSecondSection = CGRectMake(0, CELL_HEIGHT_SECTION1, self.frame.size.width, self.frame.size.height-CELL_HEIGHT_SECTION1);
        UIBezierPath *recta2 = [UIBezierPath bezierPathWithRect:boundsSecondSection];
        [[self cellBackColorDark] setFill];
        [recta2 fill];
        
        UIBezierPath *trianglePath = [UIBezierPath bezierPath];
        [trianglePath moveToPoint:CGPointMake(10.0, 0.0+CELL_HEIGHT_SECTION1)];
        [trianglePath addLineToPoint:CGPointMake(20.0, 10.0+CELL_HEIGHT_SECTION1)];
        [trianglePath addLineToPoint:CGPointMake(30.0, 0.0+CELL_HEIGHT_SECTION1)];
        [trianglePath closePath];
        [[self cellBackColor] setFill];
        [trianglePath fill];
        
        // Image tally marks
        //if (true){
        if(![self.subviews containsObject:self.images]){
            
            self.images = [[UICollectionView alloc] initWithFrame:boundsSecondSection
                                             collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
            [self.images setDataSource:self];
            [self.images setDelegate:self];
            [self.images setBackgroundColor:nil];
            [self.images registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"gridcell"];
            
        }
        else // always update the frame (in case of new lines / rotation of device)
            self.images.frame = boundsSecondSection;
        
        //update images
        [self updateGridCells];

        [self addSubview:self.images];
        
        if(self.loadAnimation){
            [self showTalliesWithDelay];
        }
        
        CGRect boundsCountLabel = CGRectMake(0, CELL_HEIGHT_SECTION1, self.frame.size.width, self.frame.size.height-CELL_HEIGHT_SECTION1);
        self.counterLabelForTally = [[UILabel alloc] initWithFrame:boundsCountLabel];
        self.counterLabelForTally.textColor = [UIColor whiteColor];
        self.counterLabelForTally.userInteractionEnabled=true;
        [self addSubview: self.counterLabelForTally];
    }
}

-(void) updateGridCells
{
    if (self.tally.counter < 6 || self.reloadCompleteCell)
    {
        [self.images reloadData];
        self.reloadCompleteCell = false;
        return;
    }
    // set the path, do not do -1 in case of add
    NSIndexPath *path = [NSIndexPath indexPathForRow:[self.images numberOfItemsInSection:0] - ((self.cellAddRemove==1)?0:1) inSection:0];
    [UIView setAnimationsEnabled:NO];
    @try{
        switch(self.cellAddRemove){
            case 1:
                [self.images insertItemsAtIndexPaths:@[path]];
                break;
            case -1:
                [self.images deleteItemsAtIndexPaths:@[path]];
                break;
            default:
                [self.images reloadItemsAtIndexPaths:@[path]];
                break;
        }
    }
    @catch(NSException * e) {
        [self.images reloadData];
    }
    [UIView setAnimationsEnabled:YES];
}

-(void) showTalliesWithDelay
{
    self.images.alpha = 0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelay:0.1];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:self];
    self.images.alpha = 1.0;
    [UIView commitAnimations];
}

// Editing of the label (UITextField)
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.titleTextField) {
        [textField resignFirstResponder];
        self.tally.title = textField.text;
        self.titleTextField.text = textField.text;
        self.titleTextField.enabled = NO;
    }
    return YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect accessoryViewFrame = self.accessoryView.frame;
    accessoryViewFrame.origin.y = (CELL_HEIGHT_SECTION1-COUNTLABEL_HEIGHT)/2;
    self.accessoryView.frame = accessoryViewFrame;
}


#pragma mark - Magic to make the UICollectionview datasource work

-(NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (self.tally.counter-1)/5+1;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *gridcell = [collectionView dequeueReusableCellWithReuseIdentifier:@"gridcell" forIndexPath:indexPath];
    
    int tmp = self.tally.counter % 5;
    if (indexPath.item > self.tally.counter/5-1) {
        gridcell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tally_%2$@%1$tu", tmp, self.tally.type]]];
    }
    else{
        gridcell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tally_%2$@%1$tu", 5, self.tally.type]]];
    }
    
    return gridcell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize mElementSize = CGSizeMake(TALLY_IMAGE_DIMENSION, TALLY_IMAGE_DIMENSION);
    return mElementSize;
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(COLLECTIONVIEW_HORIZONTAL_SPACING,COLLECTIONVIEW_VERTICAL_SPACING,0,0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0;
}

@end