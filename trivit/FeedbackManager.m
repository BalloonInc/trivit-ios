//
//  FeedbackManager.m
//  trivit
//
//  Created by Pieterjan Criel on 16/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feedback.h"
#import "FeedbackManager.h"
#import "RKMIMETypeSerialization.h"
#import "RKLog.h"

@implementation FeedbackManager

-(void)FeedbackWithMessage:(NSString *)message rating:(NSInteger)rating software:(NSString * )software device:(NSString *)device name:(NSString *)name email:(NSString *)email {
    
    Feedback *dataObject = [[Feedback alloc] init];
    [dataObject setFeedbackMessage:message];
    [dataObject setScaleValue:rating];
    [dataObject setSoftwareIdentifier:software];
    [dataObject setDeviceIdentifier:device];
    [dataObject setName:name];
    [dataObject setEmail:email];

    NSURL *baseURL = [NSURL URLWithString:@"http://ballooninc.be/api/"];
    
    AFHTTPClient * client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    RKObjectMapping *requestMapping =  [[Feedback defineLoginRequestMapping] inverseMapping];
    
    [objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[Feedback class] rootKeyPath:nil method:RKRequestMethodAny]];
    // what to print
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKLogConfigureByName("Restkit/Network", RKLogLevelDebug);
    
    RKObjectMapping *responseMapping = [Feedback defineLoginRequestMapping];
    
    [objectManager addResponseDescriptor:[RKResponseDescriptor
                                          responseDescriptorWithMapping:responseMapping method:RKRequestMethodAny pathPattern:@"feedback" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)
                                          
                                          ]];
    
    [objectManager setRequestSerializationMIMEType: RKMIMETypeJSON];
    
    [objectManager postObject:dataObject path:@"feedback"
                   parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                       NSLog(@"It Worked: %@", [mappingResult array]);
                       
                   } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                       NSLog(@"It Failed: %@", error);
                       
                   }];
}

@end
