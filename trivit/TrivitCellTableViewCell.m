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
@property (strong, nonatomic) UILabel *titleForTally;
@property (strong, nonatomic) UILabel *counterForTally;

@end

@implementation TrivitCellTableViewCell

#pragma mark - Initialization

-(UIColor*)cellBackColor{
    if (!_cellBackColor){
        //random color for every cell
        //_cellBackColor=[Colors randomColorUsingColorSet: [Colors iOSColors]];
        
        //permutated color for every cell
        _cellBackColor = [Colors colorWithIndex:self.cellIdentifier usingColorSet: [Colors flatDesignColorsLight]];
    }
    return _cellBackColor;
}

-(UIColor*)cellBackColorDark {
    if (!_cellBackColorDark){
        _cellBackColorDark = [Colors colorWithIndex:self.cellIdentifier usingColorSet: [Colors flatDesignColorsDark]];
    }
    return _cellBackColorDark;
}

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

#pragma mark -

-(void) setIsCollapsed:(BOOL)isCollapsed
{
    _isCollapsed = isCollapsed;
    [self setNeedsDisplay];
}


-(Counter*)counter{
    if (!_counter){_counter = [[Counter alloc] init];}
    return _counter;
}

- (void)drawRect:(CGRect)rect
{
    [self.titleForTally removeFromSuperview];
    [self.counterForTally removeFromSuperview];

    int hs1 = 30.0; // height first section (sloppy code)
    
    CGRect boundsTitleLabel = CGRectMake(10, 0, self.frame.size.width-10, hs1);
    CGRect boundsCountLabel = CGRectMake(10, hs1, self.frame.size.width-10, self.frame.size.height-hs1);
    CGRect boundsSecondSection = CGRectMake(0, hs1, self.frame.size.width, self.frame.size.height-hs1);
    
    UIBezierPath *recta = [UIBezierPath bezierPathWithRect:self.bounds];   
    [recta addClip];
    [[self cellBackColor] setFill];
    [recta fill];
    
    UIBezierPath *recta2 = [UIBezierPath bezierPathWithRect:boundsSecondSection];
    [[self cellBackColorDark] setFill];
    [recta2 fill];
    
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    [aPath moveToPoint:CGPointMake(10.0, 0.0+hs1)];
    [aPath addLineToPoint:CGPointMake(20.0, 10.0+hs1)];
    [aPath addLineToPoint:CGPointMake(30.0, 0.0+hs1)];
    [aPath closePath];
    [[self cellBackColor] setFill];
    [aPath fill];
    
    if (self.isCollapsed){
        self.titleForTally = [[UILabel alloc] initWithFrame:boundsTitleLabel];
        self.titleForTally.text = self.counter.title;
        self.titleForTally.textColor = [UIColor whiteColor]; // whiteColor text
        [self addSubview: self.titleForTally];
    }
    else{
        self.counterForTally = [[UILabel alloc] initWithFrame:boundsCountLabel];
        self.counterForTally.text = self.counterString;
        self.counterForTally.textColor = [UIColor whiteColor];
        [self addSubview: self.counterForTally];

    }

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
