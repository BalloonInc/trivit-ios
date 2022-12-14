//
//  AppDelegate.m
//  trivit
//
//  Created by Wouter Devriendt on 25/06/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "MainListViewController.h"
#import <NewRelicAgent/NewRelic.h>
#import "DataKit.h"
#import "TallyModel.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Google/Analytics.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self startNewRelic];
    [self startGoogleAnalytics];
    [self initApp];
    [self createDynamicShortcutItems];
    return YES;
}

-(void) openTrivitAtIndex: (NSInteger) index{
    UINavigationController* navController = (UINavigationController*) self.window.rootViewController;
    MainListViewController *mainController = (MainListViewController*) [navController topViewController];
    [mainController jumpToTrivitAtStartup: index];
    if (mainController.viewAppeared)
        [mainController applicationDidBecomeActive:nil];

}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler{
    if ([userActivity.activityType isEqualToString: CSSearchableItemActionType]) {
        NSInteger uniqueIdentifier = [[userActivity.userInfo objectForKey:@"kCSSearchableItemActivityIdentifier"] integerValue];
        [self openTrivitAtIndex:uniqueIdentifier];
    }
    
    return true;
    
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self startNewRelic];
    [self initApp];
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    NSMutableArray *lastUsedTrivits = [defaults objectForKey:@"lastUsedTrivitsIndexes"];
    NSInteger trivitToIncrement;
    
    UINavigationController* navController = (UINavigationController*) self.window.rootViewController;
    MainListViewController *mainController = (MainListViewController*) [navController topViewController];
    if ([shortcutItem.type isEqualToString:@"be.ballooninc.trivit.AddTrivit"]) {
        [mainController addNewTrivitAtStartup];
    }
    else if ([shortcutItem.type isEqualToString:@"be.ballooninc.trivit.IncrementLastTrivit"]) {
        trivitToIncrement = [[lastUsedTrivits lastObject] integerValue];
        
        [mainController incrementTrivitAtStartup: trivitToIncrement];
    }
    else if ([shortcutItem.type isEqualToString:@"be.ballooninc.trivit.IncrementPreviousLastTrivit"]) {
        trivitToIncrement = [[lastUsedTrivits objectAtIndex:[lastUsedTrivits count]-2] integerValue];
        [mainController incrementTrivitAtStartup: trivitToIncrement];
        
    }
    else{
        NSLog( @"Unknown shortcut pressed (%@), just starting the application.",shortcutItem.type);
    }
    
}

- (void)createDynamicShortcutItems {
    
    // create several (dynamic) shortcut items
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    NSMutableArray *lastUsedTrivits = [defaults objectForKey:@"lastUsedTrivitsTitles"];
    NSString *lastTrivit;
    NSString *previousLastTrivit;
    bool onlyOneTrivit = false;
    
    switch ([lastUsedTrivits count]) {
        case 0:
            [UIApplication sharedApplication].shortcutItems=nil;
            return;
            break;
        case 1:
            lastTrivit = [lastUsedTrivits lastObject];
            onlyOneTrivit = true;
            break;
        default:
            lastTrivit = [lastUsedTrivits lastObject];
            previousLastTrivit = [lastUsedTrivits objectAtIndex:[lastUsedTrivits count]-2];
            break;
    }
    
    
    UIApplicationShortcutItem *item1 = [[UIApplicationShortcutItem alloc]
                                        initWithType:@"be.ballooninc.trivit.IncrementLastTrivit"
                                        localizedTitle:NSLocalizedString(@"Increment Trivit:",@"dynamic shortcut item")
                                        localizedSubtitle:lastTrivit
                                        icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay]
                                        userInfo:nil];
    UIApplicationShortcutItem *item2 = [[UIApplicationShortcutItem alloc]
                                        initWithType:@"be.ballooninc.trivit.IncrementPreviousLastTrivit"
                                        localizedTitle:NSLocalizedString(@"Increment Trivit:",@"dynamic shortcut item")
                                        localizedSubtitle:previousLastTrivit
                                        icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay]
                                        userInfo:nil];
    
    // add all items to an array
    NSArray *items;
    if(onlyOneTrivit)
        items = @[item1];
    else
        items = @[item1,item2];
    
    // add the array to our app
    [UIApplication sharedApplication].shortcutItems = items;
}


- (void)startNewRelic{
    //New Relic analytics
#ifdef DEBUG
    NSLog(@"New relic not started, DEBUG mode on!");
#else
    [NewRelicAgent startWithApplicationToken:@"__NEW_RELIC_TOKEN__"];
#endif
}

- (void) startGoogleAnalytics{
#ifdef DEBUG
    NSLog(@"Google Analytics not started, DEBUG mode on!");
#else
    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
    gai.logger.logLevel = kGAILogLevelVerbose;  // remove before app release
#endif
}

- (void) initApp{
    // Fetch Main Storyboard
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Instantiate Root Navigation Controller
    UINavigationController *rootNavigationController = (UINavigationController *) [mainStoryboard instantiateViewControllerWithIdentifier:@"rootNavigationController"];
    
    // Configure View Controller
    MainListViewController *mainViewController = (MainListViewController *) [rootNavigationController topViewController];
    // migrate store if needed
    [DataAccess.sharedInstance migrateStore];
    
    if ([mainViewController isKindOfClass:[MainListViewController class]]) {
        self.managedObjectContext = DataAccess.sharedInstance.managedObjectContext;
        [mainViewController setManagedObjectContext:self.managedObjectContext];
    }
    
    // Configure Window
    [self.window setRootViewController:rootNavigationController];
    
}

-(void) applicationUpdateIndex:(UIApplication *)application{
    self.bgTask = [application beginBackgroundTaskWithName:@"Trivit indexing" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[@"be.ballooninc"] completionHandler:^(NSError * _Nullable error) {
            if(error){
                NSLog(@"clearing index failed");
                return;
            }
            error=nil;
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TallyModel"];
            [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
            NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc]
                                                                    initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                    sectionNameKeyPath:nil
                                                                    cacheName:nil];
            
            [fetchedResultsController performFetch:&error];
            NSMutableArray *searchableItems = [[NSMutableArray alloc] init];
            
            for (int i = 0; i<[fetchedResultsController.fetchedObjects count]; i++) {
                TallyModel *tally = (TallyModel*) [fetchedResultsController.fetchedObjects objectAtIndex:i];
                CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString*)kUTTypeText];
                attributeSet.title = [NSString stringWithFormat: @"%@: %ld",tally.title, (long)[tally.counter integerValue]];
                attributeSet.contentDescription = NSLocalizedString(@"Trivit count", @"string for in the search");
                CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:[NSString stringWithFormat:@"%d",i] domainIdentifier:@"be.ballooninc" attributeSet:attributeSet];
                [searchableItems addObject:item];
            }
            
            [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:searchableItems completionHandler:^(NSError * _Nullable error) {
                if(error)
                    NSLog(@"Indexing failed.");
                [application endBackgroundTask:self.bgTask];
                self.bgTask = UIBackgroundTaskInvalid;
            }];
        }];
    });
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    // URL is myapp://discount-scheme/id304
    if ([url.scheme isEqualToString:@"trivit"]) {
        if (url.absoluteString.length>9){
            int index;
            if ([[NSScanner scannerWithString:[[url absoluteString] substringFromIndex:9]] scanInt:&index] && index >=0) {
                [self openTrivitAtIndex: index];
            }
            else if ([[url absoluteString] isEqualToString:@"trivit://new"]){
                UINavigationController* navController = (UINavigationController*) self.window.rootViewController;
                MainListViewController *mainController = (MainListViewController*) [navController topViewController];

                [mainController addNewTrivitAtStartup];
            }
        
        return YES;
        }
    }
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [DataAccess.sharedInstance saveManagedObjectContext];
    [self createDynamicShortcutItems];
    [self applicationUpdateIndex: application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [DataAccess.sharedInstance saveManagedObjectContext];
    [self createDynamicShortcutItems];
    [self applicationUpdateIndex: application];
}

@end
