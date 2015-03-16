//
//  DataAccess.m
//  trivit
//
//  Created by Wouter Devriendt on 17/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "DataAccess.h"
#import "AppDelegate.h"
#import <UIKit/UIKit.h>

@interface DataAccess()
@property(strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property(strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation DataAccess

+ (DataAccess*) sharedInstance {
    static DataAccess *sharedDataAccess = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataAccess = [[self alloc] init];
    });
    return sharedDataAccess;
}


- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
        
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"trivits" withExtension:@"momd"];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSString *applicationDocumentsDirectory = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.ballooninc.trivit.Documents"] path];
    
    NSString *sqlitePath = [NSString stringWithFormat: @"%@/%@", applicationDocumentsDirectory, @"trivits.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:sqlitePath];

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return _persistentStoreCoordinator;
}

#pragma mark Helper Methods

- (void)saveManagedObjectContext {
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        if (error) {
            NSLog(@"Unable to save changes.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
    }
}

- (void)migrateStore {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([[defaults valueForKey:@"migratedTo2.0"] boolValue])
        return;

    // grab the current store
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *oldStoreURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"trivits.sqlite"];
    
    NSPersistentStore *oldStore = [self.persistentStoreCoordinator persistentStoreForURL:oldStoreURL];
    
    if(oldStore){
        
        NSString *applicationDocumentsDirectory = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.ballooninc.trivit.Documents"] path];
        
        NSString *sqlitePath = [NSString stringWithFormat: @"%@/%@", applicationDocumentsDirectory, @"trivits.sqlite"];
        NSURL *newStoreURL = [NSURL fileURLWithPath:sqlitePath];
        
        // migrate current store to new URL
        [self.persistentStoreCoordinator migratePersistentStore:oldStore toURL:newStoreURL options:nil withType:NSSQLiteStoreType error:nil];
    }

    
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"migratedTo2.0"];
    
}


@end
