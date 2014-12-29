//
//  FeedbackManager.h
//  trivit
//
//  Created by Pieterjan Criel on 16/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feedback_old.h"
#import "RKObjectManager.h"
#import "FeedbackManager.h"

@interface FeedbackManager : NSObject

@property (nonatomic, strong) Feedback_old *dataObject;
@property (nonatomic, strong) RKObjectManager *objectManager;
@property (nonatomic, strong) AFHTTPClient * client;

-(void)feedbackWithMessage:(NSString *)message rating:(NSInteger)rating software:(NSString * )software device:(NSString *)device name:(NSString *)name email:(NSString *)email;
-(void)feedbackWithObject:(Feedback_old *) dataObject;
@end
