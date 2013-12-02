//
//  URPlace.m
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import "URPlace.h"

@implementation URPlace
@synthesize name, location, windows, descriptions, icon;

-(URPlace *)initWithName:(NSString *)given{
	if((self = [super init])){
		[self refreshDates];
		name = given;
	}
	return self;
}

//Key: day, Object: Array of arrays, top-level being windows, bottom-level being open/closed NSDates
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
			if([[closedDate earlierDate:openDate] isEqualToDate:closedDate]){
				NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
				dayComponent.day = 1;
				closedDate = [calendar dateByAddingComponents:dayComponent toDate:closedDate options:0];
			}

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

	for(NSArray *w in [dateWindows objectForKey:weekday]){
		if([w[0] isKindOfClass:NSString.class])
			return NO;
			
		for(NSArray *ww in w){
			NSDate *open = ww[0];
			NSDate *closed = ww[1];
			
			if([[open earlierDate:date] isEqualToDate:open] && [[closed laterDate:date] isEqualToDate:closed])
				return YES;
		}
	}//end for
	
	return NO;
	
	/*
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *givenComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
	for(NSString *s in windows[@([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday).stringValue]){
		if([s rangeOfString:@"-"].location == NSNotFound)
			return NO;
		
		NSArray *comp = [s componentsSeparatedByString:@"-"];
		float open = [comp[0] integerValue];
		float closed = [comp[1] floatValue];
		float curr =  [givenComponents hour] + [givenComponents minute]/60;
		
		if(fmod(open, 12) <= curr && fmod(closed, 12) >= curr)
			return YES;
	}
	
	return NO;*/
}

-(NSString *)descForDate:(NSDate *)date{
	return nil;
}

-(NSString *)nextWindowForDate:(NSDate *)date{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSArray *best;
	
	for(NSArray *w in [dateWindows objectForKey:@([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday).stringValue]){
		if([w[0] isKindOfClass:NSString.class]){
			int nextDay = fmod([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday+1,7)==0?7:fmod([gregorian components:NSWeekdayCalendarUnit fromDate:date].weekday+1,7);
			NSArray *nextWindows = [dateWindows objectForKey:@(nextDay).stringValue];
			NSArray *firstWindowInNext = nextWindows[0][0];
			NSDate *firstOpenDateInNext = firstWindowInNext[0];
			NSDate *firstClosedDateInNext = firstWindowInNext[1];

			if([[firstOpenDateInNext laterDate:date] isEqualToDate:date])
				return [self open:firstOpenDateInNext andClosedDateToString:firstClosedDateInNext];
			else
				return w[0];
		}//end if
		
		for(NSArray *ww in w){
			NSDate *open = ww[0];
			NSDate *closed = ww[1];
			if([[open earlierDate:date] isEqualToDate:open] && [[closed laterDate:date] isEqualToDate:closed])
				return [self open:open andClosedDateToString:closed];
		
			if(!best)
				best = @[open, closed];
		
			else if([[open laterDate:date] isEqualToDate:open])
				if([[open earlierDate:best[0]] isEqualToDate:open])
					best = @[open, closed];
			}
		}//end for
	
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

@end