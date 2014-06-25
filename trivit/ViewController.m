//
//  ViewController.m
//  trivit
//
//  Created by Wouter Devriendt on 25/06/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "ViewController.h"
#import "CounterList.h"
#import "Counter.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (nonatomic,strong) CounterList* counterlist;
@property (nonatomic,strong) Counter* testCounter;
@end

@implementation ViewController

- (IBAction)increaseTellyCounter:(UIButton *)sender
{
    [self.testCounter addTally];
    NSLog(@"count: %i", self.testCounter.counter);
    [self updateUI];
}

-(void) updateUI
{
    NSMutableString *buttonLabelText;
    buttonLabelText = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i<self.testCounter.counter; i++) {
        [buttonLabelText appendString:@"|"];
        [self.testButton setTitle:buttonLabelText forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testCounter = [[Counter alloc] init];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
