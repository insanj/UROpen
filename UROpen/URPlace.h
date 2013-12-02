//
//  URPlace.h
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URPlace : NSObject {
	NSDictionary *dateWindows;
}

@property (nonatomic, retain) NSString *name, *plan, *location;
@property (nonatomic, retain) NSDictionary *windows;
@property (nonatomic, retain) NSDictionary *descriptions; //key: day, object: array of descriptions
@property (nonatomic, retain) UIImage *icon;

-(URPlace *)initWithName:(NSString *)given;
-(void)refreshDates;
-(BOOL)openForDate:(NSDate *)date;				//if place is open for given date
-(NSString *)descForDate:(NSDate *)date;		//description for given date
-(NSString *)nextWindowForDate:(NSDate *)date;	//formatted XX:XX-XX:XX for date

@end