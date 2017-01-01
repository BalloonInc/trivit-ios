//
//  TallyM.m
//  trivit
//
//  Created by Wouter on 18/12/14.
//  Copyright (c) 2014 Balloon Inc. All rights reserved.
//

#import "TallyModel.h"
#import "DataKit.h"

@implementation TallyModel

@dynamic color;
@dynamic counter;
@dynamic createdAt;
@dynamic isCollapsed;
@dynamic title;
@dynamic type;

-(id) initWithCoder: (NSCoder *)decoder {
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TallyModel" inManagedObjectContext:[[DataAccess sharedInstance] managedObjectContext]];
    self = [super initWithEntity:entity insertIntoManagedObjectContext:nil];

    self.color = [decoder decodeObjectForKey:@"color"];
    self.counter = [decoder decodeObjectForKey:@"counter"];
    self.createdAt = [decoder decodeObjectForKey:@"createdAt"];
    self.isCollapsed = [decoder decodeObjectForKey:@"isCollapsed"];
    self.title = [decoder decodeObjectForKey:@"title"];
    self.type = [decoder decodeObjectForKey:@"type"];

    return self;
}

- (void) encodeWithCoder: (NSCoder *)encoder {
    [encoder encodeObject:self.color forKey:@"color"];
    [encoder encodeObject:self.counter forKey:@"counter"];
    [encoder encodeObject:self.createdAt forKey:@"createdAt"];
    [encoder encodeObject:self.isCollapsed forKey:@"isCollapsed"];
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.type forKey:@"type"];
}
@end
