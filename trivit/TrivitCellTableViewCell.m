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

-(Counter*)counter{
    if (!_counter){_counter = [[Counter alloc] init];}
    return _counter;
}

- (void)drawRect:(CGRect)rect
{
    [self.titleForTally removeFromSuperview];
    [self.counterForTally removeFromSuperview];

    UIBezierPath *recta = [UIBezierPath bezierPathWithRect:self.bounds];
    [recta addClip];
    self.cellBackColor = [Colors colorWithIndex:self.cellIdentifier usingColorSet:self.colorset];
    [[self cellBackColor] setFill];
    [recta fill];
    CGRect bounds = CGRectMake(10, 0, self.frame.size.width-10, self.frame.size.height);
    if (self.isCollapsed){
        self.titleForTally = [[UILabel alloc] initWithFrame:bounds];
        self.titleForTally.text = self.counter.title;
        self.titleForTally.textColor = [UIColor whiteColor]; // whiteColor text
        [self addSubview: self.titleForTally];
    }
    else{
        self.counterForTally = [[UILabel alloc] initWithFrame:bounds];
        self.counterForTally.text = self.counterString;
        self.counterForTally.textColor = [UIColor whiteColor];
        [self addSubview: self.counterForTally];

    }

}

-(void) resetColor
{
    self.cellBackColor = [Colors colorWithIndex:self.cellIdentifier usingColorSet:self.colorset];
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
