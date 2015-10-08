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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self startNewRelic];
    [self initApp];
    [self createDynamicShortcutItems];
    return YES;
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
        NSLog(@"Pressed shortcut for adding a new trivit");
    }
    else if ([shortcutItem.type isEqualToString:@"be.ballooninc.trivit.IncrementLastTrivit"]) {
        NSLog(@"Pressed shortcut for last trivit");
        trivitToIncrement = [[lastUsedTrivits lastObject] integerValue];
    
        [mainController incrementTrivitAtStartup: trivitToIncrement];
    }
    else if ([shortcutItem.type isEqualToString:@"be.ballooninc.trivit.IncrementPreviousLastTrivit"]) {
        NSLog(@"Pressed shortcut for previous last trivit");
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
                                        localizedTitle:@"Increment Trivit:"
                                        localizedSubtitle:lastTrivit
                                        icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTaskCompleted]
                                        userInfo:nil];
    UIApplicationShortcutItem *item2 = [[UIApplicationShortcutItem alloc]
                                        initWithType:@"be.ballooninc.trivit.IncrementPreviousLastTrivit"
                                        localizedTitle:@"Increment Trivit:"
                                        localizedSubtitle:previousLastTrivit
                                        icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTaskCompleted]
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [DataAccess.sharedInstance saveManagedObjectContext];
    [self createDynamicShortcutItems];
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
}


@end
