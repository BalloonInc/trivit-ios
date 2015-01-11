//
//  FeedbackManager.h
//  trivit
//
//  Created by Pieterjan Criel on 16/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feedback+Mapping.h"
#import "RKObjectManager.h"
#import "Feedback+Mapping.h"

@interface FeedbackManager : NSObject

@property(nonatomic, strong) RKObjectManager *objectManager;
@property(nonatomic, strong) AFHTTPClient *client;

- (void)feedbackWithMessage:(NSString *)message rating:(NSInteger)rating software:(NSString *)software device:(NSString *)device name:(NSString *)name email:(NSString *)email managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)feedbackWithObject:(Feedback *)dataObject managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end
