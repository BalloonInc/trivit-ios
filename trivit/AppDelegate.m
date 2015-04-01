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
    //New Relic analytics
    //[NewRelicAgent startWithApplicationToken:@"__NEW_RELIC_TOKEN__"];

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

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [DataAccess.sharedInstance saveManagedObjectContext];
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
}


@end
