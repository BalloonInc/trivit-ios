//
//  DetailInterfaceController.m
//  trivit
//
//  Created by Wouter Devriendt on 05/02/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import "DetailInterfaceController.h"
#import "WKTableVIewRowController.h"

@interface DetailInterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *interfaceTable;

@end


@implementation DetailInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.title = [context objectForKey:@"title"];
    self.lightColor = [context objectForKey:@"lightColor"];
    self.darkColor = [context objectForKey:@"darkColor"];
    
    self.count = [[context objectForKey:@"count"] integerValue];

    [self loadTableData];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    NSLog(@"detail activated");
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    NSLog(@"detail de-activated");

}

- (void)configureRowControllerAtIndex:(NSInteger)index {
    WKTableVIewRowController *listItemRowController = [self.interfaceTable rowControllerAtIndex:index];
    [listItemRowController hideCounter:true];

    if(index==0){

    [listItemRowController setBackgroundColorCell:[self lightColor]];
    [listItemRowController hideCounter:true];
    [listItemRowController setItemName:self.title];

    }
    else{
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

@end



