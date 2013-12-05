//
//  URPlace.h
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URPlace : NSObject

typedef enum {
	URCampus,
    URUnlimited,
    URNone
} URPlanType;

@property (nonatomic, retain) NSString *name, *location;
@property (nonatomic, retain) NSMutableDictionary *dateWindows, *openPasts;
@property (nonatomic, retain) NSDictionary *windows;
@property (nonatomic, retain) UIImage *icon;
@property (nonatomic, assign) URPlanType plan;

-(URPlace *)initWithName:(NSString *)given;
-(void)refreshDates;
-(BOOL)openForDate:(NSDate *)date;				//if place is open for given date
-(NSString *)descForDate:(NSDate *)date;		//description for given date
-(NSString *)nextWindowForDate:(NSDate *)date;	//formatted XX:XX-XX:XX for date

-(NSComparisonResult)nameCompare:(URPlace *)given;
-(NSComparisonResult)mealCompare:(URPlace *)given;
-(NSComparisonResult)openCompare:(URPlace *)given;

@end