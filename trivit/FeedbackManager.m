//
//  FeedbackManager.m
//  trivit
//
//  Created by Pieterjan Criel on 16/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feedback_old.h"
#import "FeedbackManager.h"
#import "RKMIMETypeSerialization.h"
#import "RKNSJSONSerialization.h"

#import "RKLog.h"

@implementation FeedbackManager

-(void)feedbackWithMessage:(NSString *)message rating:(NSInteger)rating software:(NSString * )software device:(NSString *)device name:(NSString *)name email:(NSString *)email {
    
    Feedback_old *dataObject = [[Feedback_old alloc] init];
    [dataObject setFeedbackMessage:message];
    [dataObject setScaleValue:rating];
    [dataObject setSoftwareIdentifier:software];
    [dataObject setDeviceIdentifier:device];
    [dataObject setName:name];
    [dataObject setEmail:email];

    [self feedbackWithObject: dataObject];
}


-(void)feedbackWithObject:(Feedback_old *) dataObject {
    
    {
    
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/html"];
    
    
    NSURL *baseURL = [NSURL URLWithString:@"http://ballooninc.be/api/"];
    
    AFHTTPClient * client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client setDefaultHeader:@"Accept" value:RKMIMETypeTextXML];
    
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    RKObjectMapping *requestMapping =  [[Feedback_old defineLoginRequestMapping] inverseMapping];
    
    [objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[Feedback_old class] rootKeyPath:nil method:RKRequestMethodAny]];
    // what to print
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKLogConfigureByName("Restkit/Network", RKLogLevelDebug);
    
    RKObjectMapping *responseMapping = [Feedback_old defineLoginRequestMapping];
    
    [objectManager addResponseDescriptor:[RKResponseDescriptor
                                          responseDescriptorWithMapping:responseMapping method:RKRequestMethodAny pathPattern:@"feedback" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)
                                          
                                          ]];
    
    [objectManager postObject:dataObject path:@"feedback"
                   parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                       NSLog(@"It Worked: %@", [mappingResult array]);
                       
                   } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                       NSLog(@"It Failed: %@", error);
                       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                       
                       
                       NSMutableArray *unsentFeedback = [defaults objectForKey:@"unsentFeedback"];
                       
                       if(!unsentFeedback)
                           unsentFeedback = [[NSMutableArray alloc] init];
                       
                       [unsentFeedback addObject:dataObject];
                       ;
                       [defaults setObject:unsentFeedback forKey:@"unsentFeedback"];

                   }];
    }
}

@end
