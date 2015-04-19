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

/*
 Shows the difference between two trivit arrays. returns 0 if identical, 1 if counts are different and 2 if titles are different
 */
+(NSInteger) whatIsUpdatedForOldArray: (NSArray *)oldArray andNewArray: (NSArray *)newArray fromApp: (NSString*)fromApp;

/*
 Copies an array of fetchedobjects to another array (array of TallyModel of course)
 */
+(NSArray*) copyLastFetchedData:(NSArray*)fetchedObjects;

@end
