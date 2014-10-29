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
@end

@implementation TrivitTableViewCell

#pragma mark - Constants
float const CELL_HEIGHT_SECTION1 = 44.0;
float const CELL_HEIGHT_SECTION2 = 88.0;
float const TALLY_IMAGE_DIMENSION = 32.;
float const COLLECTIONVIEW_HORIZONTAL_SPACING = 15.;
float const COLLECTIONVIEW_VERTICAL_SPACING = 5.;

#pragma mark - update tally functions

- (void)increaseTallyCounter
{
    [self.tally addTally];
    [self setNeedsDisplay];
}

- (void)decreaseTallyCounter
{

    [self.tally decreaseTally];
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

- (void) configureCountLabelWithInteger:(int) integer
{
    if (!self.countLabel){
        self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
        [[self cellBackColorDark] setFill];
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

- (void)drawRect:(CGRect)rect
{
    [self.titleTextField removeFromSuperview];
    [self.counterLabelForTally removeFromSuperview];
    [self.countLabel removeFromSuperview];
    [self.images removeFromSuperview];
    [self.modImage removeFromSuperview];
    
    // Bounds
    CGRect boundsTitleLabel = CGRectMake(0, 0, self.frame.size.width, CELL_HEIGHT_SECTION1);
    CGRect boundsCountLabel = CGRectMake(0, CELL_HEIGHT_SECTION1, self.frame.size.width, self.frame.size.height-CELL_HEIGHT_SECTION1);
    CGRect boundsSecondSection = CGRectMake(0, CELL_HEIGHT_SECTION1, self.frame.size.width, self.frame.size.height-CELL_HEIGHT_SECTION1);
    
    // first section
    UIBezierPath *recta = [UIBezierPath bezierPathWithRect:self.bounds];   
    [recta addClip];

    [[self cellBackColor] setFill];
    [recta fill];
    
    // Label in first section
    self.titleTextField = [[PaddingUITextField alloc] initWithFrame:boundsTitleLabel];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.firstLineHeadIndent = 10;
    NSAttributedString *attributedTitle = [[NSAttributedString alloc ] initWithString:self.tally.title attributes:@{NSParagraphStyleAttributeName: paragraphStyle}];
    self.titleTextField.attributedText = attributedTitle;
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
    
    [self configureCountLabelWithInteger:(int)self.tally.counter];

    if (!self.isCollapsed){
        
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
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        self.images = [[UICollectionView alloc] initWithFrame:boundsSecondSection collectionViewLayout:layout];
        [self.images setDataSource:self];
        [self.images setDelegate:self];
        [self.images setBackgroundColor:nil];
        [self.images registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"gridcell"];
        self.images.delegate = self;
        
        self.accessoryView = nil; // no accessoryView in expanded mode
        
        self.modImage = [[UIImageView alloc] init];
        
        [self.images registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"gridcell"];
        [self.images reloadData];

        if(self.loadAnimation){
            [self showTalliesWithDelay];
        }
       [self addSubview:self.images];
        
        self.counterLabelForTally = [[UILabel alloc] initWithFrame:boundsCountLabel];
        self.counterLabelForTally.textColor = [UIColor whiteColor];
        self.counterLabelForTally.userInteractionEnabled=true;
        [self addSubview: self.counterLabelForTally];
    }
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

#pragma mark - Magic to make the UICollectionview datasource work

-(NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (self.tally.counter-1)/5+1;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TrivitCollectionViewCell *gridcell = [collectionView dequeueReusableCellWithReuseIdentifier:@"gridcell" forIndexPath:indexPath];
    int tmp = self.tally.counter % 5;
    
    NSString *tally_type = @"";
    if ([[self.tally.title substringToIndex:1]  isEqual: @"_"])
        tally_type = @"ch_";
    
    gridcell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tally_%2$@%1$tu", 5, tally_type]]];
    if (indexPath.item > self.tally.counter/5-1) {
        gridcell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tally_%2$@%1$tu", tmp, tally_type]]];
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
