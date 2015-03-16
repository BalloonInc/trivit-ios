//
//  InterfaceController.h
//  trivit WatchKit Extension
//
//  Created by Wouter on 20/11/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController
@property (strong, nonatomic) NSMutableArray *sampleDataTitles;
@property (strong, nonatomic) NSMutableArray *sampleDataCounts;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
