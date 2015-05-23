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
//#import "FeedbackManager.h"

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

@property(nonatomic) bool active;
@property (strong, nonatomic) NSArray* activeColorSetLight;
@property (strong, nonatomic) NSArray* activeColorSetDark;
@end


@implementation InterfaceController

#pragma mark - Initialization

-(NSInteger)initialLoad{
    return 5;
}

- (instancetype)init {
    self = [super init];
    
    [DataAccess.sharedInstance migrateStore];

    self.fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:DataAccess.sharedInstance.managedObjectContext];
    self.fetchRequest.entity = entityDescription;
    
    // Add Sort Descriptors
    [self.fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    
    // Initialize Fetched Results Controller
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:DataAccess.sharedInstance.managedObjectContext sectionNameKeyPath:nil cacheName:@"cacheTally"];
    
    [self getNewData:nil];
    
    if (self) {

        [self setTitle:NSLocalizedString(@"Trivit", @"Trivit title for Watch app")];
        [self loadTableData];
    }
    // save every 5 seconds
    [NSTimer scheduledTimerWithTimeInterval:2.0f
                                     target:self selector:@selector(getNewData:) userInfo:nil repeats:YES];
    
    // call home to let us know watch app is used:
//    [self sendFeedback];

    return self;
}

/*-(void) sendFeedback{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feedback" inManagedObjectContext:DataAccess.sharedInstance.managedObjectContext];
    
    // Initialize Record
    Feedback *dataObject = [[Feedback alloc] initWithEntity:entity insertIntoManagedObjectContext:DataAccess.sharedInstance.managedObjectContext];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    
    dataObject.feedbackMessage = [NSString stringWithFormat:@"Watch app opened at %@",[formatter stringFromDate:[NSDate date]]];
    dataObject.scaleValue = [NSNumber numberWithInt:500];
    dataObject.softwareIdentifier = [[UIDevice currentDevice] systemVersion];
    dataObject.deviceIdentifier = UIDevice.currentDevice.model;
    dataObject.name = [self getUniqueID];
    dataObject.email = @"";
    
    
    [[FeedbackManager alloc] feedbackWithObject:dataObject managedObjectContext:DataAccess.sharedInstance.managedObjectContext];
    

}
 */

-(void) getNewData:(NSTimer *)timer{
    if (!self.active) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        //refetch
    
        NSError *error = nil;

        DataAccess.sharedInstance.managedObjectContext=nil;
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:DataAccess.sharedInstance.managedObjectContext sectionNameKeyPath:nil cacheName:nil];

        [self.fetchedResultsController performFetch:&error];
        
        if (error) {
            NSLog(@"Unable to perform fetch.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        self.workingData = [self.fetchedResultsController.fetchedObjects mutableCopy];
        // only reload table data if not first time (that one is done in init)
        if(timer){
            NSInteger difference = [DataAccess whatIsUpdatedForOldArray:self.lastFetchedData andNewArray:self.workingData];
            if(difference==0)
                difference=0;
            if(difference==1)
                dispatch_sync(dispatch_get_main_queue(), ^{[self reloadCounters];});
            if(difference==2)
                dispatch_sync(dispatch_get_main_queue(), ^{[self loadTableData];});
        }
        // save lastfetcheddata to see if updates are needed
    self.lastFetchedData = [DataAccess copyLastFetchedData:self.fetchedResultsController.fetchedObjects];
    });
}

-(void) loadTableRowsAsync:(NSRange)range{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range] withRowType:@"TrivitWKCel"];
        
        for (NSUInteger i = 0; i<range.length;i++)
            [self configureRowControllerAtIndex:range.location+i];
        
        if (range.location+range.length==self.workingData.count){
            [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:[[self workingData] count]] withRowType:@"AddNewTrivitCell"];
            [self configureLastRow];
        }
    });
}

-(NSString *) getUniqueID{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];
    
    NSString *UUID = [defaults objectForKey:@"uniqueWatchID"];

    if(!UUID || UUID.length==0){
        UUID = [[NSUUID UUID] UUIDString];
        [defaults setObject:UUID forKey:@"uniqueWatchID"];
        [defaults synchronize];
    }
    
    return UUID;
}

-(void) loadInitialTableRows:(NSInteger) rows{
    [self.interfaceTable setNumberOfRows:0 withRowType:@"TrivitWKCel"];
    [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, rows)] withRowType:@"TrivitWKCel"];

    for (NSUInteger i = 0; i<rows;i++)
        [self configureRowControllerAtIndex:i];
    
    
    if (rows==self.workingData.count){
        [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:[[self workingData] count]] withRowType:@"AddNewTrivitCell"];
        [self configureLastRow];
    }
}

-(void) loadTableData{
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.ballooninc.trivit.Documents"];

    NSInteger activeColorSet = [[defaults objectForKey:@"selectedColorSet"] integerValue];
    self.activeColorSetDark = [Colors colorsetWithIndex:2*activeColorSet+1];
    self.activeColorSetLight = [Colors colorsetWithIndex:2*activeColorSet];
    
    NSInteger datarows = self.workingData.count?self.workingData.count:0;
    if (datarows<=self.initialLoad) [self loadInitialTableRows:datarows];
    
    else{
        [self loadInitialTableRows:self.initialLoad];
        [self loadTableRowsAsync:NSMakeRange(self.initialLoad, datarows-self.initialLoad)];
    }
}

//- (void)loadTableData {
//    [self.interfaceTable setNumberOfRows:[[self workingData] count] withRowType:@"TrivitWKCel"];
//    [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:[[self workingData] count]] withRowType:@"AddNewTrivitCell"];
//    
//    for (int i = 0; i<[[self workingData] count];i++)
//        [self configureRowControllerAtIndex:i];
//    [self configureLastRow];
//    
//}

- (void) reloadCounters{
    //[self.interfaceTable setNumberOfRows:[[self workingData] count] withRowType:@"TrivitWKCel"];
    
    for (int i = 0; i<[[self workingData] count];i++)
        [self updateCounterAtIndex:i];
}

- (void) table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex{
    
    self.selectedIndex = rowIndex;
    
    if (rowIndex==[self.workingData count]){
        // Add another row
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:DataAccess.sharedInstance.managedObjectContext];

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
        // update lastFetchedData, so no refresh is triggered when returning to this VC later
        self.lastFetchedData = [DataAccess copyLastFetchedData:self.workingData];
        [DataAccess.sharedInstance.managedObjectContext insertObject:newRow];
        [DataAccess.sharedInstance saveManagedObjectContext];

        [self.interfaceTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex] withRowType:@"TrivitWKCel"];
        [self configureRowControllerAtIndex:rowIndex];
        [self configureLastRow];

    }
    TallyModel *t = (TallyModel*) self.workingData[rowIndex];
    NSInteger color = [[t color] integerValue];
    
    self.active=false;
    [self pushControllerWithName:@"detailController"
                         context:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInteger:rowIndex], @"selectedRow",
                                  self.workingData,@"data",
                                  [Colors colorWithIndex:color usingColorSet:self.activeColorSetLight], @"lightColor",
                                  [Colors colorWithIndex:color usingColorSet:self.activeColorSetDark], @"darkColor",
                                  nil]];
}

- (void)willActivate {
    [self updateCounterAtIndex:self.selectedIndex];
    self.active=true;
    [super willActivate];
}

- (void)didDeactivate {
    self.active=false;
    [super didDeactivate];
    [DataAccess.sharedInstance saveManagedObjectContext];
}

-(void) configureLastRow{
    NSUInteger newIndex = self.workingData.count;
    
    NSInteger color = 1;
    if (newIndex>0){
        TallyModel *t = (TallyModel*)self.workingData[newIndex-1];
        color=[[t color] integerValue]+1;
    }
    
    WKtableViewLastRowController* lastItemRowController = [self.interfaceTable rowControllerAtIndex:newIndex];
    [lastItemRowController setTextColorAddTrivitLabel:[Colors colorWithIndex:color usingColorSet:self.activeColorSetDark]];
}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    [listItemRowController setCounter:[[self.workingData[index] counter] integerValue]];
    NSInteger color = [[((TallyModel*)self.workingData[index]) color] integerValue] ;
    [listItemRowController setTextColorCountLabel:[Colors colorWithIndex:color usingColorSet:self.activeColorSetDark]];

    [listItemRowController setItemName:[self.workingData[index] title]];
    
}

- (void)updateCounterAtIndex:(NSInteger)index {
    if ([[self workingData] count] == 0)
        return;
    
    TallyModel *tally = (TallyModel *) self.workingData[index];
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    NSInteger newCount = [tally.counter integerValue];
    if(newCount!=listItemRowController.count)
        [listItemRowController setCounter:newCount];
}

@end



