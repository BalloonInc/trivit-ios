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

@interface DetailInterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;
@property (strong, nonatomic) NSMutableArray *data;
@property (nonatomic) NSInteger selectedRow;
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
    NSLog(@"detail activated");
}


- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    //[self.counts replaceObjectAtIndex:self.selectedRow withObject:[NSNumber numberWithInteger:self.count]];
    [super didDeactivate];
    NSLog(@"detail de-activated");

}
- (IBAction)minusButtonPressed {
    self.count--;
    [self reloadCounter];
}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];

    if(index==0){

        [listItemRowController setBackgroundColorCell:[self lightColor]];
        [listItemRowController setItemName:self.title];
        [listItemRowController setCounter:-1];
        [listItemRowController setBackgroundColorButton:[self darkColor]];

    }
    else{
        [listItemRowController hideCounter:true];
        [listItemRowController setBackgroundColorCell:[self darkColor]];
        [listItemRowController setItemName:[NSString stringWithFormat:@"%ld",(long)self.count]];
    }
    
}
- (void)loadTableData {
    [self.interfaceTable setNumberOfRows:2 withRowType:@"detailHeader"];

    [self.interfaceTable setRowTypes:@[@"detailHeader",@"detailCount"]];
    [self configureRowControllerAtIndex:0];
    [self configureRowControllerAtIndex:1];
    
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {

    self.count = MAX(self.count+((rowIndex==1)?1:-1),0);
    [self reloadCounter];
    TallyModel *tally = self.data[self.selectedRow];
    tally.counter = [NSNumber numberWithInteger:self.count];
    [self.data replaceObjectAtIndex:self.selectedRow withObject:tally];

}


-(void) reloadCounter{
    [self configureRowControllerAtIndex:1];
}

@end



