//
//  settingButtonCollectionViewCell.m
//  trivit
//
//  Created by Wouter Devriendt on 27/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "SettingButtonCell.h"

@interface SettingButtonCell ()
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;
@property (weak, nonatomic) IBOutlet UIButton *cellButton;

@end

@implementation SettingButtonCell

-(void) setButtonText:(NSString *)buttonText{
    _buttonText = buttonText;
    self.cellLabel.text = buttonText;
}


-(void) setButtonImage:(UIImage *)buttonImage
{
    _buttonImage = buttonImage;
    [self.cellButton setImage:buttonImage forState:UIControlStateNormal];
}

-(void) setImageAlpha:(float)alpha
{
    self.cellButton.alpha = alpha;
}

@end
