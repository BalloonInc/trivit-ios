//
//  Feedback.m
//  trivit
//
//  Created by Pieterjan Criel on 9/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Feedback.h"

@implementation Feedback (Mapping)

+(RKObjectMapping*)defineLoginRequestMapping {
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Feedback_old class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"feedbackMessage":   @"feedbackMessage",
                                                  @"deviceIdentifier":   @"deviceIdentifier",
                                                  @"softwareIdentifier":   @"softwareIdentifier",
                                                  @"scaleValue":   @"scaleValue",
                                                  @"name":   @"name",
                                                  @"email":   @"email"
                                                  }];
    return mapping;
}

@end

