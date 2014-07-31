//
//  TrivitCollectionViewCell.h
//  trivit
//
//  Created by Pieterjan Criel on 30/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrivitCollectionViewCell : UICollectionViewCell

@property (nonatomic) NSInteger count;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) int countForTally;

@end
