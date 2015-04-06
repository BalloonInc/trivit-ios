//
//  InterfaceController.m
//  trivit WatchKit Extension
//
//  Created by Wouter on 20/11/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "InterfaceController.h"
#import "WKTableVIewRowController.h"
#import "WKtableViewLastRowController.h"
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
@property(nonatomic) bool newTrivitAdded;
@end


@implementation InterfaceController

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    
    self.managedObjectContext = DataAccess.sharedInstance.managedObjectContext;
    [DataAccess.sharedInstance migrateStore];
    self.fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:self.managedObjectContext];
    self.fetchRequest.entity = entityDescription;
    
    // Add Sort Descriptors
    [self.fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    [self getNewData:nil];
    
    if (self) {

        [self setTitle:NSLocalizedString(@"Trivit", @"Trivit title for Watch app")];
        [self loadTableData];
    }
    // save every 5 seconds
    [NSTimer scheduledTimerWithTimeInterval:5.0f
                                     target:self selector:@selector(getNewData:) userInfo:nil repeats:YES];

    return self;
}

-(void) getNewData:(NSTimer *)timer{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        [DataAccess.sharedInstance saveManagedObjectContext];
        //refetch
        NSError *error = nil;
        [self.fetchedResultsController performFetch:&error];
        
        if (error) {
            NSLog(@"Unable to perform fetch.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        self.workingData = [self.fetchedResultsController.fetchedObjects mutableCopy];
        // only reload table data if not first time (that one is done in init)
        if(timer){
            NSInteger difference = [DataAccess whatIsUpdatedForOldArray:self.lastFetchedData andNewArray:self.workingData];
            if(difference==1)
                [self reloadCounters];
            if(difference==2)
                [self loadTableData];
        }
        // save lastfetcheddata to see if updates are needed
        self.lastFetchedData = self.fetchedResultsController.fetchedObjects;
    });

}

- (void)loadTableData {
    [self.interfaceTable setNumberOfRows:[[self workingData] count] withRowType:@"TrivitWKCel"];
    [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:[[self workingData] count]] withRowType:@"AddNewTrivitCell"];
    
    for (int i = 0; i<[[self workingData] count];i++)
        [self configureRowControllerAtIndex:i];
    [self configureLastRow];
    
}

- (void)reloadCounters {
    [self.interfaceTable setNumberOfRows:[[self workingData] count] withRowType:@"TrivitWKCel"];
    
    for (int i = 0; i<[[self workingData] count];i++)
        [self updateCounterAtIndex:i];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    
    self.selectedIndex = rowIndex;
    
    if (rowIndex==[self.workingData count]){
        // Add another row
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:self.managedObjectContext];

        TallyModel *newRow = [[TallyModel alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        // display in 12HR/24HR (i.e. 11:25PM or 23:25) format according to User Settings
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        newRow.title = [NSString stringWithFormat:@"⌚️ added %@",[dateFormatter stringFromDate:[NSDate date]]];


        newRow.counter = [NSNumber numberWithInteger:0];
        newRow.color = [NSNumber numberWithInteger:[((TallyModel*)[self.workingData lastObject]).color integerValue]+1];
        newRow.type = @"";
        newRow.createdAt = [NSDate date];


        [self.workingData addObject:newRow];
        [DataAccess.sharedInstance.managedObjectContext insertObject:newRow];

        
        // set boolean to process table next time view appears
        self.newTrivitAdded=true;
    }
    
    
    [self pushControllerWithName:@"detailController"
                         context:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInteger:rowIndex], @"selectedRow",
                                  self.workingData,@"data",
                                  [Colors colorWithIndex:rowIndex usingColorSet:[Colors flatDesignColorsLight]], @"lightColor",
                                  [Colors colorWithIndex:rowIndex usingColorSet:[Colors flatDesignColorsDark]], @"darkColor",
                                  nil]];
}

- (void)willActivate {
    if(self.newTrivitAdded) // if new trivit is added, reload the whole list
        [self loadTableData];
    else
        [self updateCounterAtIndex:self.selectedIndex];
    self.newTrivitAdded=false;
    [super willActivate];
    [DataAccess.sharedInstance saveManagedObjectContext];
    
}

- (void)didDeactivate {
    [super didDeactivate];
    [DataAccess.sharedInstance saveManagedObjectContext];
}

-(void) configureLastRow{
    NSUInteger newIndex = self.workingData.count;
    WKtableViewLastRowController* lastItemRowController = [self.interfaceTable rowControllerAtIndex:newIndex];
    [lastItemRowController setTextColorAddTrivitLabel:[Colors colorWithIndex:newIndex usingColorSet:[Colors flatDesignColorsDark]]];

}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    [listItemRowController setCounter:[[self.workingData[index] counter] integerValue]];
    [listItemRowController setTextColorCountLabel:[Colors colorWithIndex:index usingColorSet:[Colors flatDesignColorsDark]]];

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



