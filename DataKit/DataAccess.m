//
//  DataAccess.m
//  trivit
//
//  Created by Wouter Devriendt on 17/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "DataAccess.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@implementation DataAccess
/*
public class var sharedInstance : DataAccess {
    struct Static {
        static var onceToken : dispatch_once_t = 0
        static var instance : DataAccess? = nil
    }
    dispatch_once(&Static.onceToken) {
        Static.instance = DataAccess()
    }
    
    return Static.instance!
}
*/

+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (NSArray*) getData{

    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    if(context){
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:context];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        //[sortDescriptor release];
        [request setEntity:entity];
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        //[request release];
        
        if (error) {
            NSLog(@"ERROR: %@ %@", [error localizedDescription], [error userInfo]);
        }
        
        if (results == nil) {
            NSLog(@"No results found");
            
        }
        else {
            NSLog(@"results %lu", (unsigned long)[results count]);
        }
    }
    return results;
}
@end
