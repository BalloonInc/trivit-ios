//
//  Feedback.m
//  trivit
//
//  Created by Pieterjan Criel on 9/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Feedback.h"

@implementation Feedback

@synthesize feedbackMessage;
@synthesize deviceIdentifier;
@synthesize softwareIdentifier;
@synthesize scaleValue;

+(RKObjectMapping*)defineLoginRequestMapping {
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Feedback class]];
    
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"feedbackMessage":   @"feedbackMessage",
                                                  @"deviceIdentifier":   @"deviceIdentifier",
                                                  @"softwareIdentifier":   @"softwareIdentifier",
                                                  @"scaleValue":   @"scaleValue",
                                                  }];
    return mapping;
}

@end

