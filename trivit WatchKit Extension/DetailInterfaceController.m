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

@property (strong, nonatomic) NSMutableArray *data;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *countLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *internalGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *countButton;
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
    //[self.titleLabel setTextColor:self.lightColor];
    [self.internalGroup setBackgroundColor:self.darkColor];
    [self reloadCounter];
    
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {

    self.count = MAX(self.count+((rowIndex==1)?1:-1),0);

    TallyModel *tally = self.data[self.selectedRow];
    tally.counter = [NSNumber numberWithInteger:self.count];
    [self.data replaceObjectAtIndex:self.selectedRow withObject:tally];

}

-(void) reloadCounter{

    NSString *labelText = [NSString stringWithFormat:@"%ld",self.count];
    [self.countButton setTitle:labelText];
}

@end



