//
//  Feedback.h
//  trivit
//
//  Created by Wouter Devriendt on 29/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Feedback : NSManagedObject

@property(nonatomic, retain) NSString *feedbackMessage;
@property(nonatomic, retain) NSString *deviceIdentifier;
@property(nonatomic, retain) NSString *softwareIdentifier;
@property(nonatomic, retain) NSNumber *scaleValue;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *email;

@end
