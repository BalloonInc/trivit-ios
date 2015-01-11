//
//  Feedback+Mapping.m
//  trivit
//
//  Created by Wouter Devriendt on 29/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Feedback+Mapping.h"

@implementation Feedback (Mapping)

+ (RKObjectMapping *)defineLoginRequestMapping {

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Feedback class]];

    [mapping addAttributeMappingsFromDictionary:@{
            @"feedbackMessage" : @"feedbackMessage",
            @"deviceIdentifier" : @"deviceIdentifier",
            @"softwareIdentifier" : @"softwareIdentifier",
            @"scaleValue" : @"scaleValue",
            @"name" : @"name",
            @"email" : @"email"
    }];
    return mapping;
}

@end
