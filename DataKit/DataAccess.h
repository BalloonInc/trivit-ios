//
//  DataAccess.h
//  trivit
//
//  Created by Wouter Devriendt on 17/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DataAccess : NSObject

@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)saveManagedObjectContext;
- (void)migrateStore;
+ (DataAccess*) sharedInstance;

@end
