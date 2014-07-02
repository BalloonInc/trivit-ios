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

- (IBAction)increaseTallyCounter:(UIButton *)sender
{
    [self.testCounter addTally];
    NSLog(@"count: %li", (long)self.testCounter.counter);
    [self updateUI];
}

- (IBAction)resetTallyCounter:(UISwipeGestureRecognizer *)sender
{
    if ([self sureYouWantToReset])
    [self.testCounter resetTally];
    NSLog(@"count: %li", (long)self.testCounter.counter);
    [self updateUI];
}

- (IBAction)decreaseTallyCounter:(UISwipeGestureRecognizer *)sender
{
    [self.testCounter decreaseTally];
    NSLog(@"count: %li", (long)self.testCounter.counter);
    [self updateUI];
}

-(bool)sureYouWantToReset
{
    //TODO: make buttons responsive :)
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Trivit" message:@"Are you sure you want to reset this TriVit?"
												   delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
	[alert show];
	[alert release];
    
    
    return true;
}

-(void) updateUI
{
    NSMutableString *buttonLabelText;
    buttonLabelText = [[NSMutableString alloc] initWithString:@""];
    for (int i = 0; i<=self.testCounter.counter; i++) {
        [buttonLabelText appendString:@"|"];
        [self.testButton setTitle:buttonLabelText forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testCounter = [[Counter alloc] init];
    
    UISwipeGestureRecognizer * rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(resetTallyCounter:)];
    
    [_testButton addGestureRecognizer:rightSwipe];
    
    UISwipeGestureRecognizer * leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(decreaseTallyCounter:)];
    
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [_testButton addGestureRecognizer:leftSwipe];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
