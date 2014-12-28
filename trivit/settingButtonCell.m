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

@end

@implementation SettingButtonCell

-(void) setButtonText:(NSString *)buttonText{
    _buttonText = buttonText;
    self.cellLabel.text = buttonText;
}

@end
