//
//  AboutControllerViewController.m
//  trivit
//
//  Created by Wouter on 22/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "AboutViewController.h"
//#import <QuartzCore/QuartzCore.h>
#import "FeedbackManager.h"


@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UIButton *highestScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *highScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *mediumScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *lowScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *lowestScoreButton;
@property (weak, nonatomic) IBOutlet UILabel *feedBackLabel;

@property (nonatomic) NSInteger score;

@property (strong, nonatomic) NSArray *feedbackTexts;
@property (weak, nonatomic) IBOutlet UITextView *feedbackDetail;

@end

@implementation AboutViewController

-(NSArray *)feedbackTexts
{
    return @[NSLocalizedString(@"Let us know how you feel:", @"feedback message"),
             NSLocalizedString(@"How is this even approved by Apple?", @"feedback message"),
             NSLocalizedString(@"Well, at least you tried...", @"feedback message"),
             NSLocalizedString(@"I've seen better, I've seen worse", @"feedback message"),
             NSLocalizedString(@"I like what I see.", @"feedback message"),
             NSLocalizedString(@"This is the best app ever!", @"feedback message"),
             ];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setScoreActive:0];
    [self layoutViews];

    // Do any additional setup after loading the view.
}

-(void) layoutViews
{
    // Add shadow
    [self.feedbackDetail.layer setBorderColor: [[UIColor grayColor] CGColor]];
    [self.feedbackDetail.layer setBorderWidth: 0.25];
    [self.feedbackDetail.layer setMasksToBounds:NO];
    [self.feedbackDetail.layer setShadowRadius:1.0f];
    self.feedbackDetail.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.feedbackDetail.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.feedbackDetail.layer.shadowOpacity = 1.0f;
    self.feedbackDetail.layer.shadowRadius = 1.0f;
}


- (IBAction)scoreButtonPressed:(id)sender
{
    UIButton *senderButton = (UIButton*) sender;
    
    [self setScoreActive:senderButton.tag];
}

- (IBAction)sendButtonPressed:(id)sender
{
    NSString * iOSVersion = [[UIDevice currentDevice] systemVersion];
    NSString * modelDevice = [[UIDevice currentDevice] model];
    [[FeedbackManager alloc] FeedbackWithMessage:self.feedbackDetail.text rating:self.score software:iOSVersion device:modelDevice];
    
    [self.navigationController popViewControllerAnimated:YES];
}



-(void) setScoreActive:(NSInteger)score
{
    self.score = score;
    // Array with all buttons
    NSArray *buttons = @[self.highestScoreButton,self.highScoreButton,self.mediumScoreButton,self.lowScoreButton,self.lowestScoreButton];
    
    NSString *imageName;
    for (UIButton* button in buttons) {
        imageName = [NSString stringWithFormat:@"score_%@_%d",(score==button.tag)?@"sel":@"nosel",button.tag];
        [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    self.feedBackLabel.text = self.feedbackTexts[score];
    self.feedBackLabel.textColor=(score>0)?[UIColor darkGrayColor]:[UIColor blackColor];
}

@end
