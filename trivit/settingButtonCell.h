//
//  settingButtonCollectionViewCell.h
//  trivit
//
//  Created by Wouter Devriendt on 27/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingButtonCell : UICollectionViewCell
@property(strong, nonatomic) NSString *buttonText;
@property(strong, nonatomic) UIImage *buttonImage;
@property(nonatomic) NSInteger buttonID;
@property(nonatomic) float imageAplha;

@end
