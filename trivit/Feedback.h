//
//  Feedback.h
//  trivit
//
//  Created by Pieterjan Criel on 9/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Feedback : NSObject {
    NSString *feedbackMessage;
    NSString *deviceIdentifier;
    NSString *softwareIdentifier;
    NSInteger scaleValue;
}


    @property (nonatomic, strong) NSString* feedbackMessage;
    @property (nonatomic, strong) NSString* deviceIdentifier;
    @property (nonatomic, strong) NSString* softwareIdentifier;
    @property (nonatomic) NSInteger scaleValue;


-(id)initFeedbackWithMessage: (NSNumber *) feedbackMessage
           withDeviceIdentifier: (NSString *) deviceIdentifier
          withSoftwareIdentifier: (NSString *) softwareIdentifier
          withScaleValue: (NSInteger) scaleValue;

@end
