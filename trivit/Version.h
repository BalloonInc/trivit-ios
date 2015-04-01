//
//  Version.h
//  trivit
//
//  Created by Wouter Devriendt on 31/03/15.
//  Copyright (c) 2015 Balloon Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Version : NSManagedObject

@property (nonatomic, retain) NSString * versionNumber;
@property (nonatomic, retain) NSDate * dateFirstOpened;

@end
