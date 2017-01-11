//
//  DetailInterfaceController.m
//  trivit
//
//  Created by Wouter Devriendt on 05/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "DetailInterfaceController.h"
#import "WKTableVIewRowController.h"
#import "InterfaceController.h"
#import "TallyModel.h"
#import "DataAccess.h"

@interface DetailInterfaceController()

@property (strong, nonatomic) NSMutableArray *data;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *countLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *internalGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *countButton;
@property (nonatomic) NSInteger selectedRow;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *minusButtonGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *trivitButtonGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *resetButtonGroup;
@end


@implementation DetailInterfaceController

- (void)awakeWithContext:(id)context {
    if ([WCSession isSupported]){
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    
    [super awakeWithContext:context];
    
    self.data = [context objectForKey:@"data"];
    self.selectedRow = [[context objectForKey:@"selectedRow"] integerValue];
    self.title = [self.data[self.selectedRow] title];
    self.lightColor = [context objectForKey:@"lightColor"];
    self.darkColor = [context objectForKey:@"darkColor"];
    self.count = [[self.data[self.selectedRow] counter] integerValue];

    [self loadTableData];
}

-(void) session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext{
    for (NSData *encodedTally in applicationContext.allValues) {
        TallyModel *newTally = [NSKeyedUnarchiver unarchiveObjectWithData:encodedTally];
        TallyModel *selectedTally = self.data[self.selectedRow];
        if ([newTally.createdAt compare:selectedTally.createdAt] == NSOrderedSame && [newTally.title isEqualToString:selectedTally.title]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.count = [newTally.counter integerValue];
                [self reloadCounter];
            });
        }
    }
}

- (IBAction)plusButtonPressed {
    self.count++;
    [self reloadCounter];
    [self sendUpdatedCount];
}

- (IBAction)minusButtonPressed {
    if(self.count>0) self.count--;
    [self reloadCounter];
    [self sendUpdatedCount];
}

- (IBAction)resetButtonPressed {
    self.count = 0;
    [self reloadCounter];
    [self sendUpdatedCount];
}

- (IBAction)deleteButtonPressed {
    [self removeTrivit];
    // TODO: remove from this list
    [self.data removeObjectAtIndex:self.selectedRow];
    [self popController];
}


- (void)loadTableData {
    [self.titleLabel setText:[self.data[self.selectedRow] title]];
    [self.internalGroup setBackgroundColor:self.darkColor];
    [self.minusButtonGroup setBackgroundColor:self.darkColor];
    [self.trivitButtonGroup setBackgroundColor:self.darkColor];
    [self.resetButtonGroup setBackgroundColor:self.darkColor];
    [self reloadCounter];
}

-(void) reloadCounter{
    // update model
    TallyModel *tally = self.data[self.selectedRow];
    tally.counter = [NSNumber numberWithInteger:self.count];
    [self.data replaceObjectAtIndex:self.selectedRow withObject:tally];
    [DataAccess.sharedInstance saveManagedObjectContext];

    // update view
    NSString *labelText = [NSString stringWithFormat:@"%ld",(long)self.count];
    [self.countButton setTitle:labelText];
}

-(void) sendUpdatedCount {
    // background transfer to iPhone
    NSMutableDictionary *updatedCounter = [[NSMutableDictionary alloc] init];

    TallyModel *newTrivit = (TallyModel *) self.data[self.selectedRow];
    newTrivit.counter = [[NSNumber alloc] initWithInt: self.count];
    NSArray *outstandingTransfers = [[WCSession defaultSession] outstandingUserInfoTransfers];
    for (WCSessionUserInfoTransfer *transfer in outstandingTransfers){
        for (NSString *key in transfer.userInfo) {
            if ([key isEqualToString:@"updatedCount"]){
                TallyModel *updatedModel = [NSKeyedUnarchiver unarchiveObjectWithData:transfer.userInfo[key]];
                
                if ([updatedModel.createdAt compare: newTrivit.createdAt] == NSOrderedSame && [updatedModel.title isEqualToString: newTrivit.title]){
                    [transfer cancel];
                    break;
                }
            }
        }
    }
    
    NSData *encodedRecord = [NSKeyedArchiver archivedDataWithRootObject: newTrivit];
    
    [updatedCounter setValue:encodedRecord forKey:@"updatedCount"];
    [[WCSession defaultSession] transferUserInfo:updatedCounter];
}

-(void) removeTrivit {
    TallyModel *trivitToRemove = (TallyModel *) self.data[self.selectedRow];

    NSData *encodedRecord = [NSKeyedArchiver archivedDataWithRootObject: trivitToRemove];
    NSMutableDictionary *deleteDict = [[NSMutableDictionary alloc] init];
    [deleteDict setValue:encodedRecord forKey:@"deleteTrivit"];
    [[WCSession defaultSession] transferUserInfo:deleteDict];
}

@end
