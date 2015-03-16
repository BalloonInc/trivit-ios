//
//  InterfaceController.m
//  trivit WatchKit Extension
//
//  Created by Wouter on 20/11/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "InterfaceController.h"
#import "WKTableVIewRowController.h"
#import "DataKit.h"
#import "TallyModel.h"

#import "Colors.h"

@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;
@property (nonatomic) NSInteger selectedIndex;

@property(strong, nonatomic) NSFetchRequest *fetchRequest;
@property(strong, nonatomic) NSFetchRequest *fetchRequestSetup;

@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsControllerSetup;

@property(strong, nonatomic) NSArray *lastFetchedData;
@property(strong, nonatomic) NSMutableArray *workingData;
@end


@implementation InterfaceController

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    
    self.managedObjectContext = DataAccess.sharedInstance.managedObjectContext;
    
    self.fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:self.managedObjectContext];
    self.fetchRequest.entity = entityDescription;
    
    // Add Sort Descriptors
    [self.fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    // Perform Fetch
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];

    [self fetchData];
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, error.localizedDescription);
    }
    
    if (self) {

        [self setTitle:NSLocalizedString(@"Trivit", @"Trivit title for Watch app")];
        [self loadTableData];
    }
    
    return self;
}

- (void) fetchData {
    // keep a copy of the last fetched data (to calculate delta if needed)
    NSArray *fetchedData = self.fetchedResultsController.fetchedObjects;
    
    // if data changed in the mean time, make a merge and save
    if (fetchedData != self.lastFetchedData){
        //TODO merge and save
        [self saveData];
    }
        
    self.lastFetchedData = self.fetchedResultsController.fetchedObjects;
    // make a working copy (mutable copy)
    self.workingData = [self.lastFetchedData mutableCopy];
}

- (void) saveData {
    
}

- (void)loadTableData {
    [self.interfaceTable setNumberOfRows:[[self workingData] count] withRowType:@"TrivitWKCel"];
    
    for (int i = 0; i<[[self workingData] count];i++) {
        [self configureRowControllerAtIndex:i];
    }
    
}

- (void)reloadCounters {
    [self.interfaceTable setNumberOfRows:[[self workingData] count] withRowType:@"TrivitWKCel"];
    
    for (int i = 0; i<[[self workingData] count];i++) {
        [self updateCounterAtIndex:i];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    
    self.selectedIndex = rowIndex;
    [self pushControllerWithName:@"detailController"
                         context:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInteger:rowIndex], @"selectedRow",
                                  self.workingData,@"data",
                                  [Colors colorWithIndex:rowIndex usingColorSet:[Colors flatDesignColorsLight]], @"lightColor",
                                  [Colors colorWithIndex:rowIndex usingColorSet:[Colors flatDesignColorsDark]], @"darkColor",
                                  nil]];
}

- (void)willActivate {

    [self updateCounterAtIndex:self.selectedIndex];

    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    NSLog(@"%@ did deactivate", self);
}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    [listItemRowController setCounter:[[self.workingData[index] counter] integerValue]];
    [listItemRowController setBackgroundColorButton:[Colors colorWithIndex:index usingColorSet:[Colors flatDesignColorsDark]]];
    [listItemRowController setBackgroundColorCell:[Colors colorWithIndex:index usingColorSet:[Colors flatDesignColorsLight]]];

    [listItemRowController setItemName:[self.workingData[index] title]];
    
}

- (void)updateCounterAtIndex:(NSInteger)index {
    if ([[self workingData] count] == 0)
        return;
    
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];
    TallyModel *tally = (TallyModel *) self.workingData[index];
    NSInteger newCount = [tally.counter integerValue];
    [listItemRowController setCounter:newCount];
}

@end



