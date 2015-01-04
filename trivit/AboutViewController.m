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
// smiley button properties
@property (weak, nonatomic) IBOutlet UIButton *highestScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *highScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *mediumScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *lowScoreButton;
@property (weak, nonatomic) IBOutlet UIButton *lowestScoreButton;

// static label properties
@property (weak, nonatomic) IBOutlet UILabel *feedBackLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

// Logic properties
@property (nonatomic) NSInteger score;
@property (strong, nonatomic) NSArray *feedbackTexts;

//user text properties
@property (weak, nonatomic) IBOutlet UITextView *feedbackDetail;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;

@end

@implementation AboutViewController

#pragma mark - Constants
int const DONEBUTTON = 0;
int const SENDBUTTON = 1;

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

-(void) setScore:(NSInteger)score
{
    // Array with all buttons
    NSArray *buttons = @[self.highestScoreButton,self.highScoreButton,self.mediumScoreButton,self.lowScoreButton,self.lowestScoreButton];
    
    for (UIButton* button in buttons)
    {
        button.imageView.image = [UIImage imageNamed:@"score_1"];
        button.imageView.alpha=(score==button.tag)?1.:.4;
    }
    self.feedBackLabel.text = self.feedbackTexts[score];
    self.feedBackLabel.textColor=(score>0)?[UIColor darkGrayColor]:[UIColor blackColor];
    _score = score;
}

#pragma mark viewDidLoad stuff
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (UIButton* button in @[self.highestScoreButton,self.highScoreButton,self.mediumScoreButton,self.lowScoreButton,self.lowestScoreButton])
        NSLog(@"Button %d tag: %f",button.tag, button.alpha);

    [self layoutViews];

    [self setPlaceHolderTextForTextView:self.feedbackDetail];

    self.rightBarButton.tag = SENDBUTTON;
    
    self.feedbackDetail.delegate = self;
    self.nameField.delegate = self;
    self.emailField.delegate = self;
    
    // subscribe to notifications for keyboard show and hide, used for changing view size
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    for (UIButton* button in @[self.highestScoreButton,self.highScoreButton,self.mediumScoreButton,self.lowScoreButton,self.lowestScoreButton])
        NSLog(@"1. Button %d alpha: %f",button.tag, button.alpha);

}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.score=0;
    for (UIButton* button in @[self.highestScoreButton,self.highScoreButton,self.mediumScoreButton,self.lowScoreButton,self.lowestScoreButton])
        NSLog(@"2. Button %d alpha: %f",button.tag, button.alpha);

}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    for (UIButton* button in @[self.highestScoreButton,self.highScoreButton,self.mediumScoreButton,self.lowScoreButton,self.lowestScoreButton])
        NSLog(@"3. Button %d alpha: %f",button.tag, button.alpha);
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

#pragma mark bar button behavior
- (IBAction)barButtonPressed:(id)sender
{
    UIBarButtonItem *button = (UIBarButtonItem*) sender;
    if (button.tag==DONEBUTTON)
        [self doneEditingDetailTextView];
    else if (button.tag==SENDBUTTON)
        [self sendFeedback];
    else
        NSLog(@"error, button not correctly labeled");
}

- (void) sendFeedback
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feedback" inManagedObjectContext:self.managedObjectContext];
    
    // Initialize Record
    Feedback *dataObject = [[Feedback alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    dataObject.FeedbackMessage = self.feedbackDetail.text;
    dataObject.ScaleValue =[NSNumber numberWithInt:self.score];
    dataObject.SoftwareIdentifier =[[UIDevice currentDevice] systemVersion];
    dataObject.DeviceIdentifier =UIDevice.currentDevice.model;
    dataObject.Name =self.nameField.text;
    dataObject.Email =self.emailField.text;
    
    

    [[FeedbackManager alloc] feedbackWithObject:dataObject managedObjectContext:self.managedObjectContext];
    
    [self.navigationController popViewControllerAnimated:YES];
}

// logic concerning the smileys
- (IBAction)scoreButtonPressed:(id)sender
{
    [self doneEditingDetailTextView];
    UIButton *senderButton = (UIButton*) sender;
    
    self.score = senderButton.tag;
}


// Dismiss keyboard for UITextView
- (void)doneEditingDetailTextView
{
    [self.feedbackDetail resignFirstResponder];
    [self.nameField resignFirstResponder];
    [self.emailField resignFirstResponder];
    
    self.rightBarButton.title = NSLocalizedString(@"Send", @"Send button for feedback");
    self.rightBarButton.tag = SENDBUTTON;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.rightBarButton.title = NSLocalizedString(@"Done", @"Done button right top when editing text view");
    self.rightBarButton.tag = DONEBUTTON;
    if(textView.textColor==[UIColor grayColor]){
        textView.textColor=[UIColor blackColor];
        textView.text=@"";
    }
}
-(void)textViewDidEndEditing:(UITextView *)textView
{
    if(!textView.text.length){
        [self setPlaceHolderTextForTextView: textView];
    }
}
-(void) setPlaceHolderTextForTextView: (UITextView *)textView
{
    textView.textColor=[UIColor grayColor];
    textView.text=NSLocalizedString(@"Your feedback", @"Placeholder text for feedback text");
}

// Dismiss keyboard for UITextfields
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

// resize view if keyboard is shown/hidden
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, kbSize.height, self.scrollView.contentInset.right);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    // restore the insets
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, 0, self.scrollView.contentInset.right);
    
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


@end
