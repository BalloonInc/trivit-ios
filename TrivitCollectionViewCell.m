//
//  TrivitCollectionViewCell.m
//  trivit
//
//  Created by Pieterjan Criel on 30/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TrivitCollectionViewCell.h"

@implementation TrivitCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code
    }
    return self;
}


#pragma mark - Magic to make the UICollectionview datasource work

-(NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 150;
    return self.countForTally/5+1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *gridcell = [collectionView dequeueReusableCellWithReuseIdentifier:@"gridcell" forIndexPath:indexPath];
    //gridcell.backgroundColor = [Colors colorWithHexString:@"BADA55"];
    
    return gridcell;
}

@end
