//
//  TrivitCellTableViewCell.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TrivitCellTableViewCell.h"
#import "Colors.h"

@interface TrivitCellTableViewCell()

@end

@implementation TrivitCellTableViewCell

float const CELL_HEIGHT_SECTION1 = 44.0;
float const CELL_HEIGHT_SECTION2 = 88.0;

#pragma mark - update tally functions

- (void)increaseTallyCounter
{
    [self.counter addTally];
    NSLog(@"count: %li", (long)self.counter.countForTally);
    [self updateTallyString];
    [self setNeedsDisplay];
}

- (void)resetTallyCounter
{
    if ([self sureYouWantToReset])
    {
        [self.counter resetTally];
        NSLog(@"count: %li", (long)self.counter.countForTally);
        [self updateTallyString];
        [self setNeedsDisplay];
    }
}

- (void)decreaseTallyCounter
{
    [self.counter decreaseTally];
    NSLog(@"count: %li", (long)self.counter.countForTally);
    [self updateTallyString];
    [self setNeedsDisplay];
}

-(bool)sureYouWantToReset
{
    //TODO: make buttons responsive :)
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Trivit" message:@"Are you sure you want to reset this trivit?"
                                                   delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
    //	[alert release];
    
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
 
 }

*/
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
-(UIColor*)cellBackColorDark {
    if (!_cellBackColorDark){
        _cellBackColorDark = [Colors colorWithIndex:self.cellIdentifier usingColorSet: [Colors flatDesignColorsDark]];
    }
    return _cellBackColorDark;
}


-(Counter*)counter{
    if (!_counter){_counter = [[Counter alloc] init];}
    return _counter;
}

- (void)drawRect:(CGRect)rect
{
    [self.titleLabelForTally removeFromSuperview];
    [self.counterLabelForTally removeFromSuperview];
    [self.images removeFromSuperview];
    
    CGRect boundsTitleLabel = CGRectMake(10, 0, self.frame.size.width-10, CELL_HEIGHT_SECTION1);
    CGRect boundsCountLabel = CGRectMake(10, CELL_HEIGHT_SECTION1, self.frame.size.width-10, self.frame.size.height-CELL_HEIGHT_SECTION1);
    CGRect boundsSecondSection = CGRectMake(0, CELL_HEIGHT_SECTION1, self.frame.size.width, self.frame.size.height-CELL_HEIGHT_SECTION1);
    
    UIBezierPath *recta = [UIBezierPath bezierPathWithRect:self.bounds];   
    [recta addClip];
    //colorset_func
    //self.cellBackColor = [Colors colorWithIndex:self.cellIdentifier usingColorSet:self.colorset];
    [[self cellBackColor] setFill];
    [recta fill];
    
    self.titleLabelForTally = [[UILabel alloc] initWithFrame:boundsTitleLabel];
    self.titleLabelForTally.text = self.counter.title;
    self.titleLabelForTally.textColor = [UIColor whiteColor]; // whiteColor text
    //test tap gesture on subview
    self.titleLabelForTally.userInteractionEnabled = true;
    [self addSubview: self.titleLabelForTally];

    if (!self.isCollapsed){
        UIBezierPath *recta2 = [UIBezierPath bezierPathWithRect:boundsSecondSection];
        [[self cellBackColorDark] setFill];
        [recta2 fill];
        
        UIBezierPath *aPath = [UIBezierPath bezierPath];
        [aPath moveToPoint:CGPointMake(10.0, 0.0+CELL_HEIGHT_SECTION1)];
        [aPath addLineToPoint:CGPointMake(20.0, 10.0+CELL_HEIGHT_SECTION1)];
        [aPath addLineToPoint:CGPointMake(30.0, 0.0+CELL_HEIGHT_SECTION1)];
        [aPath closePath];
        [[self cellBackColor] setFill];
        [aPath fill];
        
        // Image tally marks
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        self.images = [[UICollectionView alloc] initWithFrame:boundsSecondSection collectionViewLayout:layout];
        [self.images setDataSource:self];
        [self.images setDelegate:self];
        [self.images setBackgroundColor:nil];
        [self.images registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"gridcell"];
        [self addSubview:self.images];
        
        
        
        self.modImage = [[UIImageView alloc] init];
        long fullTally = self.counter.countForTally/5;
        
        if(fullTally>0){
            for (int i=0; i<fullTally; i++) {
                NSIndexPath *indexpath = [[NSIndexPath alloc] initWithIndex:i];
                UICollectionViewCell *gridcell = [self.images cellForItemAtIndexPath:indexpath];
                [gridcell addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tally_5"]]];
            }
        }
        int mod = self.counter.countForTally % 5;
        UIImage *myimg = [UIImage imageNamed:[NSString stringWithFormat:@"tally_%i",mod]];
        self.modImage.image=myimg;
        self.modImage.frame = CGRectMake(10, 10.+CELL_HEIGHT_SECTION1, 32, 32);
        [self addSubview:self.modImage];
        
        self.counterLabelForTally = [[UILabel alloc] initWithFrame:boundsCountLabel];
//        self.counterLabelForTally.text = self.counterString;
        self.counterLabelForTally.textColor = [UIColor whiteColor];
        //test tap gesture on subview
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

#pragma mark - Magic to make the UICollectionview datasource work

-(NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 150;
    return self.counter.countForTally/5+1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *gridcell = [collectionView dequeueReusableCellWithReuseIdentifier:@"gridcell" forIndexPath:indexPath];
    //gridcell.backgroundColor = [Colors colorWithHexString:@"BADA55"];

    return gridcell;
}

-(void) setup
{
    //self.backgroundColor = nil;
    //self.opaque = false;
    //self.contentMode = UIViewContentModeRedraw;
}



- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
