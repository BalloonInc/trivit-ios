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
#import <WatchConnectivity/WatchConnectivity.h>

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
    [super awakeWithContext:context];
    
    self.data = [context objectForKey:@"data"];
    self.selectedRow = [[context objectForKey:@"selectedRow"] integerValue];
    self.title = [self.data[self.selectedRow] title];
    self.lightColor = [context objectForKey:@"lightColor"];
    self.darkColor = [context objectForKey:@"darkColor"];
    self.count = [[self.data[self.selectedRow] counter] integerValue];

    [self loadTableData];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    DataAccess.sharedInstance.watchDetailsActive = true;
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    DataAccess.sharedInstance.watchDetailsActive = false;

}
- (IBAction)plusButtonPressed {
    self.count++;
    [self reloadCounter];
}

- (IBAction)minusButtonPressed {
    if(self.count>0) self.count--;
    [self reloadCounter];
}

- (IBAction)resetButtonPressed {
    self.count = 0;
    [self reloadCounter];
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
    
    // background transfer to iPhone
    NSMutableDictionary *updatedCounter = [[NSMutableDictionary alloc] init];
    
    TallyModel *newTrivit = (TallyModel *) self.data[self.selectedRow];
    newTrivit.counter = [[NSNumber alloc] initWithInt: self.count];
    NSData *encodedRecord = [NSKeyedArchiver archivedDataWithRootObject: newTrivit];

    [updatedCounter setValue:encodedRecord forKey:@"updatedCount"];
    [[WCSession defaultSession] transferUserInfo:updatedCounter];
}

@end



