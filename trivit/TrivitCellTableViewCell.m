//
//  TrivitCellTableViewCell.m
//  trivit
//
//  Created by Wouter Devriendt on 17/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TrivitCellTableViewCell.h"

@implementation TrivitCellTableViewCell



#pragma mark - Initialization
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

-(void) setIsCollapsed:(BOOL)isCollapsed
{
    _isCollapsed = isCollapsed;
    [self setNeedsDisplay];
}


-(Counter*)Counter{
    if (!_counter){_counter = [[Counter alloc] init];}
    return _counter;
}


- (void)drawRect:(CGRect)rect
{
    if (self.isCollapsed){
        UIBezierPath *rect = [UIBezierPath bezierPathWithRect:self.bounds];
        [rect addClip];
        [[UIColor orangeColor] setFill];
        [rect fill];
        UILabel *titleForTally = [[UILabel alloc] initWithFrame:self.bounds];
        titleForTally.text = self.counter.title;
        
    }
    else{
        
    }

    /*
    // Drawing code
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:[self cornerRadius]];
    [roundedRect addClip];
    [[UIColor whiteColor] setFill];
    UIRectFill(self.bounds);
    
    [[UIColor blackColor] setStroke];
    roundedRect.lineWidth = 2.0;
    [roundedRect stroke];
    
    if (self.faceUp)
    {
        NSString *cardString = [NSString stringWithFormat:@"%@%@",[self rankAsString], self.suit];
        NSLog(@"%@",cardString);
        
        UIImage *faceImage = [UIImage imageNamed:cardString];
        
        if (faceImage)
        {
            CGRect imageRect = CGRectInset(self.bounds, self.bounds.size.width * (1.0-self.faceCardScaleFactor), self.bounds.size.height * (1.0-self.faceCardScaleFactor));
            [faceImage drawInRect:imageRect];
        }
        else
            [self drawPips];
        [self drawCorners];
    }
    else{
        [[UIImage imageNamed:@"cardback"] drawInRect:self.bounds];
    }
    */
}



-(void) setup
{
    self.backgroundColor = nil;
    self.opaque = false;
    self.contentMode = UIViewContentModeRedraw;
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
