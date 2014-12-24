//
//  Feedback.h
//  trivit
//
//  Created by Pieterjan Criel on 9/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"

@interface Feedback : NSObject
    @property (nonatomic, strong) NSString* feedbackMessage;
    @property (nonatomic, strong) NSString* deviceIdentifier;
    @property (nonatomic, strong) NSString* softwareIdentifier;
    @property (nonatomic) NSInteger scaleValue;
    @property (nonatomic, strong) NSString* name;
    @property (nonatomic, strong) NSString* email;

+(RKObjectMapping*)defineLoginRequestMapping;

@end
