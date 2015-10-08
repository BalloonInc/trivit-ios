//
//  DataAccess.m
//  trivit
//
//  Created by Wouter Devriendt on 17/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "DataAccess.h"
#import "AppDelegate.h"
#import "Version.h"
#import <UIKit/UIKit.h>
#import "TallyModel.h"

@interface DataAccess()
@property(strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property(strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(strong, nonatomic,readonly) NSString *latestVersion;
@property(strong, nonatomic) NSUserDefaults *defaults;

@end

@implementation DataAccess

@synthesize watchDetailsActive = _watchDetailsActive;
@synthesize watchInterfaceActive = _watchInterfaceActive;
/*
 Shows the difference between two trivit arrays. returns 0 if identical, 1 if counts are different and 2 if titles are different
 */
+(NSInteger) whatIsUpdatedForOldArray: (NSArray *)oldArray andNewArray: (NSArray *)newArray{
    if(oldArray.count != newArray.count)
        return 2;
    
    NSInteger res=0;
    
    for (int i=0; i<oldArray.count;i++){
        TallyModel *oldTrivit = (TallyModel *) oldArray[i];
        TallyModel *newTrivit = (TallyModel *) newArray[i];

        // if one title is different, return 2;
        if(![oldTrivit.title isEqualToString:newTrivit.title])
            return 2;
        // if counters are different, set res=1. Do not return yet since later on a title can be different
        if([oldTrivit.counter integerValue] != [newTrivit.counter integerValue])
            res=1;
    }
    
    return res;
}

+(NSArray*) copyLastFetchedData:(NSArray*)fetchedObjects{
    NSMutableArray* lastFetchedData = [[NSMutableArray alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:DataAccess.sharedInstance.managedObjectContext];
    for (TallyModel* tm in fetchedObjects) {
        TallyModel *t = [[TallyModel alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
        t.title=tm.title;
        t.counter=tm.counter;
        [lastFetchedData addObject:t];
    }
    return lastFetchedData;
}

-(NSString*) latestVersion{
    // if last entry of the versions table is the current version, don't migrate
    NSString *version = [self.defaults objectForKey:@"latestVersion"];
    if(version)
        return version;
    return @"";
}

-(NSUserDefaults *) defaults{
    if (!_defaults) _defaults = [NSUserDefaults standardUserDefaults];
    return _defaults;
}

-(BOOL) isWatchActive{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    
    bool watchInterfaceActive = [[defaults objectForKey:@"watchInterfaceActive"] boolValue];
    bool watchDetailsActive = [[defaults objectForKey:@"watchDetailsActive"] boolValue];
    
    //NSLog(@"watchInterfaceActive: %i",watchInterfaceActive);
    //NSLog(@"watchDetailsActive: %i",watchDetailsActive);

    return watchInterfaceActive || watchDetailsActive;
}


-(BOOL) watchInterfaceAtive{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    return [[defaults objectForKey:@"watchInterfaceActive"] boolValue];
}

-(void) setWatchInterfaceActive:(bool)watchInterfaceActive{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    [defaults setObject:[NSNumber numberWithBool:watchInterfaceActive] forKey:@"watchInterfaceActive"];
    [defaults synchronize];
    NSLog(@"watchInterfaceActive: %i",watchInterfaceActive);
}


-(BOOL) watchDetailsAtive{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    return [[defaults objectForKey:@"watchDetailsActive"] boolValue];
}
-(void) setWatchDetailsActive:(bool)watchDetailsActive{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    [defaults setObject:[NSNumber numberWithBool:watchDetailsActive] forKey:@"watchDetailsActive"];
    [defaults synchronize];
    NSLog(@"watchDetailsActive: %i",watchDetailsActive);

}

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
    NSURL *applicationDocumentsDirectory = nil;
    if ([self.latestVersion isEqualToString:@""])
        applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

    else
        applicationDocumentsDirectory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.ballooninc.trivit.Documents"];
    

    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat: @"trivits%@.sqlite", self.latestVersion]];

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES],NSMigratePersistentStoresAutomaticallyOption,[NSNumber numberWithBool:YES],NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return _persistentStoreCoordinator;
}

#pragma mark Helper Methods

- (void)saveManagedObjectContext {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        // if there are changes, save them
        if([self.managedObjectContext hasChanges]){
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                if (error) {
                    NSLog(@"Unable to save changes.");
                    NSLog(@"%@, %@", error, error.localizedDescription);
                }
            }
        }
    });
}

- (void)migrateStore {
    NSString * currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    currentVersion = [currentVersion stringByReplacingOccurrencesOfString:@"." withString:@""];

    NSArray *versions = [self getVersions];
    // if last entry of the versions table is the current version, don't migrate
    if(versions){
        Version *lastVersion = (Version*) [versions lastObject];

        if ([lastVersion.versionNumber isEqualToString:currentVersion])
            return;
    }
    
    // grab the current store
    NSURL *oldStoreURL = [self.persistentStoreCoordinator.persistentStores.lastObject URL];
    
    NSPersistentStore *oldStore = [self.persistentStoreCoordinator persistentStoreForURL:oldStoreURL];

    if(oldStore){
        
        NSString *applicationDocumentsDirectory = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.ballooninc.trivit.Documents"] path];
        
        NSString *sqlitePath = [NSString stringWithFormat: @"%@/trivits%@.sqlite", applicationDocumentsDirectory, currentVersion];
        NSURL *newStoreURL = [NSURL fileURLWithPath:sqlitePath];
        
        // migrate current store to new URL
        NSError *error = nil;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: YES],NSMigratePersistentStoresAutomaticallyOption,[NSNumber numberWithBool:YES],NSInferMappingModelAutomaticallyOption, nil];

        NSPersistentStore *store = [self.persistentStoreCoordinator migratePersistentStore:oldStore toURL:newStoreURL options:options withType:NSSQLiteStoreType error:&error];
        NSLog(@"New store location: %@", store.URL);
        if(error){
            NSLog(@"An error occured while migrating the store: %@",error.description);
        }
    }
    self.managedObjectContext=nil;
    self.managedObjectModel=nil;
    self.persistentStoreCoordinator=nil;
    
    [self.defaults setObject:currentVersion forKey:@"latestVersion"];
    
    // save this upgrade in the versions table
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Version" inManagedObjectContext:self.managedObjectContext];
    
    Version *newRow = [[Version alloc] initWithEntity:entityDescription
                       insertIntoManagedObjectContext:self.managedObjectContext];
    
    newRow.dateFirstOpened = [NSDate date];
    newRow.versionNumber = currentVersion;
    
    [self.managedObjectContext save:nil];

}

-(NSArray*)getVersions{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Version" inManagedObjectContext:self.managedObjectContext];
    
    // If entityDescription is nil, we are in a version of the Core Data model that doesn't have the 'Version' entity yet. Just return nil
    if(!entityDescription)
        return nil;
    
    fetchRequest.entity = entityDescription;
    
    // Add Sort Descriptors
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateFirstOpened" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    // Perform Fetch
    NSError *error = nil;
    [fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        return nil;
    }
    return fetchedResultsController.fetchedObjects;

}

-(void) sendFeedback{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    
    NSMutableArray *watchFeedBackArray = [defaults objectForKey:@"WatchFeedbackArray"];
    
    if(!watchFeedBackArray)
        watchFeedBackArray = [[NSMutableArray alloc] init];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    NSString *message = [NSString stringWithFormat:@"Watch app opened at %@",[formatter stringFromDate:[NSDate date]]];
    NSString *os = [[UIDevice currentDevice] systemVersion];
    NSString *model = UIDevice.currentDevice.model;
    NSString *name = [self getUniqueWatchID];

    [watchFeedBackArray addObject:[NSArray arrayWithObjects:message,os,model,name, nil]];
    
    [defaults setObject:watchFeedBackArray forKey:@"WatchFeedbackArray"];
    [defaults synchronize];
 }


-(NSString *) getUniqueWatchID{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    
    NSString *UUID = [defaults objectForKey:@"uniqueWatchID"];
    
    if(!UUID || UUID.length==0){
        UUID = [[NSUUID UUID] UUIDString];
        [defaults setObject:UUID forKey:@"uniqueWatchID"];
        [defaults synchronize];
    }
    
    return UUID;
}


@end
