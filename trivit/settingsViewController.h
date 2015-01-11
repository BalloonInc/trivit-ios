//
//  settingsViewController.h
//  trivit
//
//  Created by Wouter on 26/07/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import <CoreData/CoreData.h>

@interface SettingsViewController : UICollectionViewController
@property(strong, nonatomic) Settings *appSettings;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
