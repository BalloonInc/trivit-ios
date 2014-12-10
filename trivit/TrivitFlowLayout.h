//
//  TrivitFlowLayout.h
//  trivit
//
//  Created by Wouter on 10/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrivitFlowLayout : UICollectionViewFlowLayout

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath;

@end
