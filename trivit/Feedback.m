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

//-(id)initFeedbackWithMessage: (NSString *) new_feedbackMessage
//        withDeviceIdentifier: (NSString *) new_deviceIdentifier
//      withSoftwareIdentifier: (NSString *) new_softwareIdentifier
//              withScaleValue: (NSInteger) new_scaleValue {
//    if(self = [super init]){
//        feedbackMessage = new_feedbackMessage;
//        deviceIdentifier = new_deviceIdentifier;
//        softwareIdentifier = new_softwareIdentifier;
//        scaleValue = new_scaleValue;
//    }
//    return self;
//}

@end

