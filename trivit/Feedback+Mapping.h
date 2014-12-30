//
//  Feedback+Mapping.h
//  trivit
//
//  Created by Wouter Devriendt on 29/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "Feedback.h"
#import "RKObjectMapping.h"

@interface Feedback (Mapping)
+(RKObjectMapping*)defineLoginRequestMapping;

@end
