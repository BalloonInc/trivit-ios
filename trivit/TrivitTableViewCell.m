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


-(float) cellHeigth
{
    float tallyCount = ceil((self.counter.countForTally / 5.));
    float divisor = self.frame.size.width / 34.;
    int rows = ceil(tallyCount/divisor);
    return CELL_HEIGHT_SECTION1 + rows*34;
}

#pragma mark - update tally functions

- (void)increaseTallyCounter
{
    [self.counter addTally];
    [self updateTallyString];
    [self setNeedsDisplay];
}

- (void)resetTallyCounter
{
    if ([self sureYouWantToReset])
    {
        [self.counter resetTally];
        [self updateTallyString];
        [self setNeedsDisplay];
    }
}

- (void)decreaseTallyCounter
{
    [self.counter decreaseTally];
    [self updateTallyString];
    [self setNeedsDisplay];
}

-(bool)sureYouWantToReset
{
    //TODO: make buttons responsive :)
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Trivit" message:@"Are you sure you want to reset this trivit?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
    return true;
}

-(void) updateTallyString
{
    NSMutableString *buttonLabelText;
    buttonLabelText = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i<self.counter.countForTally; i++) {
        [buttonLabelText appendString:@"|"];
    }
    self.counterString = buttonLabelText;
}


#pragma mark - lazy instantiators

-(void) setIsCollapsed:(BOOL)isCollapsed
{
    _isCollapsed = isCollapsed;
    [self setNeedsDisplay];
}

//colorset_func
/*
 @synthesize cellBackColor = _cellBackColor;

-(UIColor*)cellBackColor
{
    if (!_cellBackColor){
        //random color for every cell
        //_cellBackColor=[Colors randomColorUsingColorSet: [Colors iOSColors]];
        
        //permutated color for every cell
        _cellBackColor=[Colors colorWithIndex:self.cellIdentifier usingColorSet: self.colorset];
        
    }
    return _cellBackColor;
}
 
 -(void) setCellBackColor:(UIColor *)cellBackColor
 {
 if (_cellBackColor!=cellBackColor) {
 _cellBackColor = cellBackColor;
 [self setNeedsDisplay];
 }
 
 }*/

-(UIColor*)cellBackColor
{
    if (!_cellBackColor){
        //random color for every cell
        //_cellBackColor=[Colors randomColorUsingColorSet: [Colors iOSColors]];
        
        //permutated color for every cell
        _cellBackColor=[Colors colorWithIndex:self.cellIdentifier usingColorSet: [Colors flatDesignColorsLight]];
        
    }
    return _cellBackColor;
}

-(UIColor*)cellBackColorDark
{
    if (!_cellBackColorDark){
        _cellBackColorDark = [Colors colorWithIndex:self.cellIdentifier usingColorSet: [Colors flatDesignColorsDark]];
    }
    return _cellBackColorDark;
}

-(Counter*)counter
{
    if (!_counter){_counter = [[Counter alloc] init];}
    return _counter;
}

- (void) configureCountLabelWithInteger:(int) integer
{
    self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
    [[self cellBackColorDark] setFill];
    self.countLabel.backgroundColor = self.cellBackColorDark;
    self.countLabel.textAlignment = 1;
    self.countLabel.textColor = [UIColor whiteColor];
    [self.countLabel.layer setCornerRadius:8.0];
    [self.countLabel.layer setMasksToBounds:YES];
    
    
    self.countLabel.text = @(integer).stringValue;
    
    //Animation
    self.countLabel.alpha = 0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelegate:self];
    self.countLabel.alpha = 1.0;
    [UIView commitAnimations];
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
    //colorset_func
    //self.cellBackColor = [Colors colorWithIndex:self.cellIdentifier usingColorSet:self.colorset];
    [[self cellBackColor] setFill];
    [recta fill];
    
    // Label in first section
    self.titleTextField = [[PaddingUITextField alloc] initWithFrame:boundsTitleLabel];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc ] initWithString:self.counter.title attributes:@{NSParagraphStyleAttributeName: paragraphStyle}];
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
    
    [self configureCountLabelWithInteger:(int)self.counter.countForTally];

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
        
        if(self.loadAnimation) {
            [self onLoadAnimation];
            self.loadAnimation = NO;
        }
        [self addSubview:self.images];
        
        self.counterLabelForTally = [[UILabel alloc] initWithFrame:boundsCountLabel];
        self.counterLabelForTally.textColor = [UIColor whiteColor];
        self.counterLabelForTally.userInteractionEnabled=true;
        [self addSubview: self.counterLabelForTally];
    }
}
//colorset_func
/*
-(void) resetColor
{
    self.cellBackColor = [Colors colorWithIndex:self.cellIdentifier usingColorSet:self.colorset];
}
*/

-(void) onLoadAnimation
{
    self.images.alpha = 0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelay:0.1];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    self.images.alpha = 1.0;
    [UIView commitAnimations];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


#pragma mark TextField closings

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

// Editing of the label (UITextField)
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.titleTextField) {
        [textField resignFirstResponder];
        self.counter.title = textField.text;
        self.titleTextField.text = textField.text;
        self.titleTextField.enabled = NO;
        
    }
    return YES;
}

#pragma mark - Magic to make the UICollectionview datasource work

-(NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.counter.countForTally/5+1;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TrivitCollectionViewCell *gridcell = [collectionView dequeueReusableCellWithReuseIdentifier:@"gridcell" forIndexPath:indexPath];
    int tmp = self.counter.countForTally % 5;

    gridcell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tally_%tu", 5]]];
    if (indexPath.item > self.counter.countForTally/5-1) {
        gridcell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tally_%tu", tmp]]];
    }
    return gridcell;
}


#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize mElementSize = CGSizeMake(32, 32);
    return mElementSize;
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(15,5,0,0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0;
}



@end
