//
//  FeedbackManager.m
//  trivit
//
//  Created by Pieterjan Criel on 16/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedbackManager.h"
#import "RKMIMETypeSerialization.h"
#import "RKNSJSONSerialization.h"

#import "RKLog.h"

@implementation FeedbackManager

-(void)feedbackWithMessage:(NSString *)message rating:(NSInteger)rating software:(NSString * )software device:(NSString *)device name:(NSString *)name email:(NSString *)email managedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feedback" inManagedObjectContext:managedObjectContext];
    
    // Initialize Record
    Feedback *dataObject = [[Feedback alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
    [dataObject setFeedbackMessage:message];
    [dataObject setScaleValue:[NSNumber numberWithInteger:rating]];
    [dataObject setSoftwareIdentifier:software];
    [dataObject setDeviceIdentifier:device];
    [dataObject setName:name];
    [dataObject setEmail:email];
    
    [self feedbackWithObject: dataObject managedObjectContext:managedObjectContext];
}

-(void)feedbackWithObject:(Feedback *) dataObject managedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"text/html"];
    
    NSURL *baseURL = [NSURL URLWithString:@"http://ballooninc.be/api/"];
    
    AFHTTPClient * client = [AFHTTPClient clientWithBaseURL:baseURL];
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    RKObjectMapping *requestMapping =  [[Feedback defineLoginRequestMapping] inverseMapping];
    
    [objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[Feedback class] rootKeyPath:nil method:RKRequestMethodAny]];
    // what to print
    
    RKObjectMapping *responseMapping = [Feedback defineLoginRequestMapping];
    
    [objectManager addResponseDescriptor:[RKResponseDescriptor
                                          responseDescriptorWithMapping:responseMapping
                                          method:RKRequestMethodAny
                                          pathPattern:@"feedback"
                                          keyPath:nil
                                          statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager setRequestSerializationMIMEType:RKMIMETypeJSON];
    
    [objectManager postObject:dataObject path:@"feedback"
                   parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                       [managedObjectContext deleteObject:dataObject];
                       [managedObjectContext save:nil];
                       
                   } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                       [managedObjectContext save:nil];
                   }];
}

@end
