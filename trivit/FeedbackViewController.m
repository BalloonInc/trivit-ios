//
//  AboutControllerViewController.m
//  trivit
//
//  Created by Wouter on 22/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "FeedbackViewController.h"
//#import <QuartzCore/QuartzCore.h>
#import "FeedbackManager.h"


@interface FeedbackViewController ()
// smiley button properties
@property(weak, nonatomic) IBOutlet UIButton *highestScoreButton;
@property(weak, nonatomic) IBOutlet UIButton *highScoreButton;
@property(weak, nonatomic) IBOutlet UIButton *mediumScoreButton;
@property(weak, nonatomic) IBOutlet UIButton *lowScoreButton;
@property(weak, nonatomic) IBOutlet UIButton *lowestScoreButton;

// static label properties
@property(weak, nonatomic) IBOutlet UILabel *feedBackLabel;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *rightBarButton;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;

// Logic properties
@property(nonatomic) NSInteger score;
@property(strong, nonatomic) NSArray *feedbackTexts;

//user text properties
@property(weak, nonatomic) IBOutlet UITextView *feedbackDetail;
@property(weak, nonatomic) IBOutlet UITextField *nameField;
@property(weak, nonatomic) IBOutlet UITextField *emailField;
@property(weak, nonatomic) IBOutlet UITextView *websiteLabel;

@property(strong, nonatomic) UIColor *placeholderTextColor;

@property(strong, nonatomic) NSTimer *beginAnimationTimer;
@end

@implementation FeedbackViewController

#pragma mark - props

- (NSArray *)feedbackTexts {
    return @[NSLocalizedString(@"Tap an image to rate:", @"feedback message"),
            NSLocalizedString(@"I don't get it.", @"feedback message"),
            NSLocalizedString(@"I am missing some things...", @"feedback message"),
            NSLocalizedString(@"I've seen better, I've seen worse.", @"feedback message"),
            NSLocalizedString(@"I like what I see.", @"feedback message"),
            NSLocalizedString(@"This is the best app ever!", @"feedback message"),
    ];
}

- (UIColor *)placeholderTextColor {
    if (!_placeholderTextColor) _placeholderTextColor = [UIColor colorWithRed:187. / 256 green:186. / 256 blue:194 / 256. alpha:1];
    return _placeholderTextColor;
}

- (void)setScore:(NSInteger)score {
    // Array with all buttons
    NSArray *buttons = @[self.highestScoreButton, self.highScoreButton, self.mediumScoreButton, self.lowScoreButton, self.lowestScoreButton];

    for (UIButton *button in buttons)
        button.alpha = (score == button.tag) ? 1. : .4;

    self.feedBackLabel.text = self.feedbackTexts[score];
    self.feedBackLabel.alpha = (score > 0) ? .75 : 1;
    _score = score;
}

#pragma mark viewDidLoad stuff

- (void)viewDidLoad {
    [super viewDidLoad];
    self.score = 0;

    // localization in label with link does not work without this:

    self.websiteLabel.text = NSLocalizedString(@"Visit us: www.trivit.be", @"website to visit");

    [self setPlaceHolderTextForTextView:self.feedbackDetail];

    self.feedbackDetail.delegate = self;
    self.nameField.delegate = self;
    self.emailField.delegate = self;

    // inset for textfields
    [self setInset:5 forTextView:self.nameField];
    [self setInset:5 forTextView:self.emailField];

    // subscribe to notifications for keyboard show and hide, used for changing view size
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [self incrementScoreAnimation:nil];
    self.beginAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:.2 target:self
                                                              selector:@selector(incrementScoreAnimation:) userInfo:nil repeats:YES];
    [super viewDidAppear:animated];
}


- (void)incrementScoreAnimation:(NSTimer *)timer {
    if (self.score == 5) {
        [self.beginAnimationTimer invalidate];
        self.beginAnimationTimer = nil;
        self.score = 0;
    }
    else
        self.score++;
}

- (void)setInset:(NSInteger)inset forTextView:(UITextField *)textField {
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, inset, textField.frame.size.height)];
    leftView.backgroundColor = textField.backgroundColor;
    textField.leftView = leftView;
    textField.leftViewMode = UITextFieldViewModeAlways;
}


#pragma mark bar button behavior

- (IBAction)barButtonPressed:(id)sender {
    [self sendFeedback];
}

- (void)sendFeedback {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feedback" inManagedObjectContext:self.managedObjectContext];

    // Initialize Record
    Feedback *dataObject = [[Feedback alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
    dataObject.FeedbackMessage = self.feedbackDetail.text;
    dataObject.ScaleValue = [NSNumber numberWithInteger:self.score];
    dataObject.SoftwareIdentifier = [[UIDevice currentDevice] systemVersion];
    dataObject.DeviceIdentifier = UIDevice.currentDevice.model;
    dataObject.Name = self.nameField.text;
    dataObject.Email = self.emailField.text;


    [[FeedbackManager alloc] feedbackWithObject:dataObject managedObjectContext:self.managedObjectContext];

    [self.navigationController popViewControllerAnimated:YES];
}

// logic concerning the smileys
- (IBAction)scoreButtonPressed:(id)sender {
    UIButton *senderButton = (UIButton *) sender;

    self.score = senderButton.tag;
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView.textColor == self.placeholderTextColor) {
        textView.textColor = [UIColor blackColor];
        textView.text = @"";
    }

}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (!textView.text.length) {
        [self setPlaceHolderTextForTextView:textView];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)setPlaceHolderTextForTextView:(UITextView *)textView {
    textView.textColor = self.placeholderTextColor;
    textView.text = NSLocalizedString(@"Your feedback (optional)", @"Placeholder text for feedback text");
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else {
        return YES;
    }
}

// resize view if keyboard is shown/hidden
- (void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, kbSize.height, self.scrollView.contentInset.right);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    // restore the insets
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, 0, self.scrollView.contentInset.right);

    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


@end
