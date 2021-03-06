//
//  URPlace.m
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import "URPlace.h"

@implementation URPlace
@synthesize name, location, dateWindows, openPasts, windows, icon, plan;

-(URPlace *)initWithName:(NSString *)given{
	if((self = [super init])){
		[self refreshDates];
		name = given;
		plan = URCampus;
		openPasts = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)refreshDates{
	NSMutableDictionary *creating = [[NSMutableDictionary alloc] init];
	NSCalendar *calendar = [NSCalendar currentCalendar];
	
	for(NSString *day in windows.allKeys){
		NSArray *curr = windows[day];
		NSMutableArray *currDated = [[NSMutableArray alloc] init];
		for(NSString *s in curr){
			if([s rangeOfString:@"-"].location == NSNotFound){
				[currDated addObject:@[s]];
				continue;
			}
				
			NSArray *dashed = [s componentsSeparatedByString:@"-"];
			int openHour = [dashed[0] floatValue];
			int openMinute = ([dashed[0] floatValue] - openHour) * 60;
			int closedHour = [dashed[1] floatValue];
			int closedMinute = ([dashed[1] floatValue] - closedHour) * 60;
	
			NSDateComponents *openDateComp = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
			[openDateComp setHour:openHour];
			[openDateComp setMinute:openMinute];
			NSDate *openDate = [calendar dateFromComponents:openDateComp];
			
			NSDateComponents *closedDateComp = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
			[closedDateComp setHour:closedHour];
			[closedDateComp setMinute:closedMinute];
			NSDate *closedDate = [calendar dateFromComponents:closedDateComp];
			
			NSDateComponents *yesterComp = [calendar components:(NSWeekdayCalendarUnit | NSHourCalendarUnit) fromDate:closedDate];
			if([[closedDate earlierDate:openDate] isEqualToDate:closedDate]){
				[openPasts setObject:@(closedDateComp.hour) forKey:@(yesterComp.weekday).stringValue];

				NSDateComponents *add = [[NSDateComponents alloc] init];
				add.weekday = 1;
				closedDate = [calendar dateByAddingComponents:add toDate:closedDate options:0];
			}//end if

			NSArray *currDateWindow = @[openDate, closedDate];
			[currDated addObject:@[currDateWindow]];
		}//end for
		
		[creating setObject:currDated forKey:day];
	}//end for
	
	dateWindows = creating;
}//end method

-(BOOL)openForDate:(NSDate *)date{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSString *weekday = @([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday).stringValue;
	NSDateComponents *curr = [[NSCalendar currentCalendar] components:(NSWeekdayCalendarUnit | NSHourCalendarUnit) fromDate:date];

	for(NSArray *w in [dateWindows objectForKey:weekday]){
		if([w[0] isKindOfClass:NSString.class])
			return NO;
			
		for(NSArray *ww in w){
			NSDate *open = ww[0];
			NSDate *closed = ww[1];
				
			int openPastHour = ((NSNumber *)[openPasts objectForKey:@(curr.weekday).stringValue]).intValue;
			if(([[open earlierDate:date] isEqualToDate:open] && [[closed laterDate:date] isEqualToDate:closed]) || (curr.hour < openPastHour))
				return YES;
		}//end for
	}//end for
	
	return NO;
}

-(NSString *)descForDate:(NSDate *)date{
	return nil;
}

-(NSString *)nextWindowForDate:(NSDate *)date{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSString *currDay = @([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday).stringValue;
	int nextDay = fmod([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday+1,7)==0?7:fmod([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday+1,7);
	NSArray *best = @[[NSDate distantFuture], [NSDate distantPast]];
	
	for(NSArray *w in [dateWindows objectForKey:currDay]){
		if([w[0] isKindOfClass:NSString.class]){
			NSArray *nextWindows = [dateWindows objectForKey:@(nextDay).stringValue];
			NSArray *firstWindowInNext = nextWindows[0][0];
			if([firstWindowInNext[0] isKindOfClass:NSString.class])
				return firstWindowInNext[0];
				
			NSDate *firstOpenDateInNext = firstWindowInNext[0];
			NSDate *firstClosedDateInNext = firstWindowInNext[1];
			return [self open:firstOpenDateInNext andClosedDateToString:firstClosedDateInNext];
		}//end if
		
		for(NSArray *ww in w){
			NSDate *open = ww[0];
			NSDate *closed = ww[1];
			
			if([[open earlierDate:date] isEqualToDate:open] && [[closed laterDate:date] isEqualToDate:closed])
				return [self open:open andClosedDateToString:closed];
						
			else if([[open laterDate:date] isEqualToDate:open])
				if([[open earlierDate:best[0]] isEqualToDate:open])
					best = @[open, closed];
		}
	}//end for
	
	if([best[0] isEqualToDate:[NSDate distantFuture]]){
		NSArray *nextWindows = [dateWindows objectForKey:@(nextDay).stringValue];
		NSArray *firstWindowInNext = nextWindows[0][0];
		if([firstWindowInNext isKindOfClass:NSString.class])
			return (NSString *)firstWindowInNext;

		NSDate *firstOpenDateInNext = firstWindowInNext[0];
		NSDate *firstClosedDateInNext = firstWindowInNext[1];
		return [self open:firstOpenDateInNext andClosedDateToString:firstClosedDateInNext];
	}
		
	//NSLog(@"looks like this window is set, returning...");
	return [self open:best[0] andClosedDateToString:best[1]];
}

-(NSString *)open:(NSDate *)first andClosedDateToString:(NSDate *)second {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *fc = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:first];
	NSDateComponents *cc = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:second];
	return [NSString stringWithFormat:@"%@:%@ %@ —\n%@:%@ %@",
			[self appendZerosIfNeeded:fmod(fc.hour, 12)==0.f?12.f:fmod(fc.hour, 12)], [self appendZerosIfNeeded:fc.minute], (fc.hour<=11)?@"am":@"pm",
			[self appendZerosIfNeeded:fmod(cc.hour, 12)==0.f?12.f:fmod(cc.hour, 12)], [self appendZerosIfNeeded:cc.minute], (cc.hour<=11)?@"am":@"pm"];
}

-(NSString *)appendZerosIfNeeded:(float)given{
	if(given - (int)given != 0.f || given == 0.f)
		return [NSString stringWithFormat:@"%i0", (int)given];
	else
		return @((int)given).stringValue;
}

-(NSComparisonResult)nameCompare:(URPlace *)given{
    return [name compare:given.name];
}

-(NSComparisonResult)mealCompare:(URPlace *)given{
	return [@(given.plan) compare:@(plan)];
}

-(NSComparisonResult)openCompare:(URPlace *)given{
	return [@([given openForDate:[NSDate date]]) compare:@([self openForDate:[NSDate date]])];
}
@end