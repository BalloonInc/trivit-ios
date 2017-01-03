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
#import <WatchConnectivity/WatchConnectivity.h>
#import "Colors.h"

@interface InterfaceController() <WCSessionDelegate>
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
    
    [self loadTableData];

    if (self) {
        [self setTitle:NSLocalizedString(@"Trivit", @"Trivit title for Watch app")];
    }

    return self;
}

-(NSMutableArray *) unencodeTrivits: (NSArray*) encodedTrivits {
    NSMutableArray *result = [[NSMutableArray alloc] init];

    for (NSData *encodedTally in encodedTrivits) {
        TallyModel *tally = [NSKeyedUnarchiver unarchiveObjectWithData:encodedTally];
        [result addObject:tally];
    }
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                 ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    return [[NSMutableArray alloc] initWithArray: [result sortedArrayUsingDescriptors:sortDescriptors]];

}

-(void) fetchDataFromPhone{
    [[WCSession defaultSession] sendMessage:@{@"getLatestStatus":@""} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {

        self.workingData = [self unencodeTrivits:replyMessage.allValues];
        NSInteger difference = [self whatIsUpdatedForOldArray:self.lastFetchedData andNewArray:self.workingData];
        if(difference==1)
            dispatch_sync(dispatch_get_main_queue(), ^{[self reloadCounters];});
        if(difference==2)
            dispatch_sync(dispatch_get_main_queue(), ^{[self loadTableData];});
        self.lastFetchedData = [self copyLastFetchedData:self.workingData];

    } errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

-(void) session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext{
    self.workingData = [self unencodeTrivits: applicationContext.allValues];

    NSInteger difference = [self whatIsUpdatedForOldArray:self.lastFetchedData andNewArray:self.workingData];
    if(difference==1)
        dispatch_sync(dispatch_get_main_queue(), ^{[self reloadCounters];});
    if(difference==2)
        dispatch_sync(dispatch_get_main_queue(), ^{[self loadTableData];});

    // save lastfetcheddata to see if updates are needed
    self.lastFetchedData = [self copyLastFetchedData:self.workingData];
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
    
    if (self.workingData == nil){
        self.workingData = [[NSMutableArray alloc] init];
    }
    NSInteger datarows = self.workingData.count?self.workingData.count:0;
    if (datarows<=self.initialLoad) [self loadInitialTableRows:datarows];
    
    else{
        [self loadInitialTableRows:self.initialLoad];
        [self loadTableRowsAsync:NSMakeRange(self.initialLoad, datarows-self.initialLoad)];
    }
}

- (void) reloadCounters{
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
        self.lastFetchedData = [self copyLastFetchedData:self.workingData];
        
        // background transfer to iPhone
        NSData *encodedRecord = [NSKeyedArchiver archivedDataWithRootObject: newRow];
        [[WCSession defaultSession] transferUserInfo:@{@"newTrivit":encodedRecord}];
        
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
    if ([WCSession isSupported]){
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    [self fetchDataFromPhone];

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
    if ((int)[self.workingData count] < (int)index+1)
        return;
    
    TallyModel *tally = (TallyModel *) self.workingData[index];
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    NSInteger newCount = [tally.counter integerValue];
    if(newCount!=listItemRowController.count)
        [listItemRowController setCounter:newCount];
}

/*
 Shows the difference between two trivit arrays. returns 0 if identical, 1 if counts are different and 2 if titles are different
 */
-(NSInteger) whatIsUpdatedForOldArray: (NSArray *)oldArray andNewArray: (NSArray *)newArray{
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

-(NSArray*) copyLastFetchedData:(NSArray*)fetchedObjects{
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

@end



