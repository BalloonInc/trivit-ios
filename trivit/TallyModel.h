//
//  TallyM.h
//  trivit
//
//  Created by Wouter on 18/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TallyModel : NSManagedObject <NSCoding>

@property(nonatomic, retain) NSNumber *color;
@property(nonatomic, retain) NSNumber *counter;
@property(nonatomic, retain) NSDate *createdAt;
@property(nonatomic, retain) NSNumber *isCollapsed;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *type;

@end
