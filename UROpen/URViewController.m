//
//  URViewController.m
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#define IS_WIDESCREEN (fabs((double)[[UIScreen mainScreen] bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#import "URViewController.h"

@implementation URViewController
@synthesize mainCollectionView, mainBar;

#pragma mark - ViewController
-(void)viewDidLoad{
	[self createPlaces];
    [super viewDidLoad];
		
	self.view.frame = [[UIScreen mainScreen] bounds];
	self.view.backgroundColor = [UIColor darkGrayColor];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	mainBar = [[URNavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
	mainBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	UINavigationItem *barItems = [[UINavigationItem alloc] init];

	UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadCollection)];
	UIBarButtonItem *filter = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"filter.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(filterTapped:)];
	[filter setImageInsets:UIEdgeInsetsMake(1.5, -15, -1.5, 15)];
	barItems.leftBarButtonItems = @[refresh, filter];
	
	UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[moreButton addTarget:self action:@selector(openInfo) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
	barItems.rightBarButtonItem = moreItem;
	
	mainBar.items = @[barItems];
	[self refreshTime];
	[self.view addSubview:mainBar];

	UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
	[flowLayout setItemSize:CGSizeMake(140, 140)];
	mainCollectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:flowLayout];
	[mainCollectionView registerNib:[UINib nibWithNibName:@"URCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"URCell"];
	
	mainCollectionView.delegate = self;
	mainCollectionView.dataSource = self;
	mainCollectionView.alwaysBounceVertical = YES;
	mainCollectionView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.9];
	mainCollectionView.contentInset = UIEdgeInsetsMake(mainBar.frame.size.height + ([UIApplication sharedApplication].statusBarFrame.size.height/10), 5, 5 + ([UIApplication sharedApplication].statusBarFrame.size.height/2), 5);
	mainCollectionView.scrollIndicatorInsets = UIEdgeInsetsMake(mainBar.frame.size.height + 5, 0, 5, 0);
	mainCollectionView.tag = 5;
	mainCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view insertSubview:mainCollectionView belowSubview:mainBar];
}//end method

-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
		if(aboutView)
			[self openInfo];
		[self enableBarButtonItems:NO];
	}
	
	else
		[self enableBarButtonItems:YES];
}//end method

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[mainCollectionView reloadItemsAtIndexPaths:[mainCollectionView indexPathsForVisibleItems]];
}

#pragma mark - User Interaction
-(void)reloadCollection{
	[self refreshTime];
	[self refreshPlaces];
	[self toggleBarButtonItems];
	
	animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
	UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:mainCollectionView snapToPoint:CGPointMake(self.view.center.x, self.view.frame.size.height * 1.5)];
	[snap setDamping:0.75];
	[animator addBehavior:snap];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[animator removeBehavior:snap];
		
		[mainCollectionView removeFromSuperview];
		[mainCollectionView reloadItemsAtIndexPaths:[mainCollectionView indexPathsForVisibleItems]];
		
		[self.view insertSubview:mainCollectionView belowSubview:mainBar];
		UISnapBehavior *back = [[UISnapBehavior alloc] initWithItem:mainCollectionView snapToPoint:CGPointMake(self.view.center.x, self.view.center.y)];
		[back setDamping:0.75];
		[animator addBehavior:back];
		[self toggleBarButtonItems];
	});
}//end method

-(void)filterTapped:(UIBarButtonItem *)sender{
	UIActionSheet *filterSheet = [[UIActionSheet alloc] initWithTitle:@"Filter" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Alphabetical", @"Meal Plan", @"Open Now", nil];
	[filterSheet showFromBarButtonItem:sender animated:YES];
}//end method

-(void)openInfo{
	UINavigationItem *buttons = (UINavigationItem *)mainBar.items[0];
	BOOL set = !buttons.leftBarButtonItem.enabled;
	for(UIBarButtonItem *b in buttons.leftBarButtonItems)
		[b setEnabled:set];
	
	BOOL newAbout = NO;
	if(!aboutView){
		newAbout = YES;
		aboutView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, self.view.frame.size.height, 250, 250)];
		UITextView *aboutText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
		aboutText.text = [NSString stringWithFormat:@"UROpen was made with love by Julian (insanj) Weiss for fellow UofR-ers.\n\nBorn over the course of Thanksgiving Break '13, and meant to be free forever.\n\nVersion %@, Build %@\n © 2013 Julian Weiss", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
		
		aboutText.backgroundColor = [UIColor clearColor];
		aboutText.font = [UIFont systemFontOfSize:18.f];
		aboutText.textAlignment = NSTextAlignmentJustified;
		aboutText.editable = NO;
		[aboutView addSubview:aboutText];
		[self.view addSubview:aboutView];
	}//end if
	
	for(UIView *v in mainCollectionView.subviews){
		[UIView animateWithDuration:0.5 animations:^{
			CGRect frame = v.frame;
			if(newAbout)
				frame.origin.x = frame.origin.x - self.view.frame.size.width;
			else
				frame.origin.x = frame.origin.x + self.view.frame.size.width;
			
			[v setFrame:frame];
		}];
	}//end for
	
	if(newAbout){
		mainCollectionView.scrollEnabled = NO;
		sample = [[[NSBundle mainBundle] loadNibNamed:@"URCollectionViewCell" owner:self options:nil] objectAtIndex:0];
		[sample setFrame:CGRectMake(self.view.center.x * 2, self.view.center.y, 140, 140)];
		((UILabel *)[sample viewWithTag:2]).text = @"Name";
		((UILabel *)[sample viewWithTag:3]).text = @"Dining Plan";
		((UILabel *)[sample viewWithTag:4]).text = @"Next Open Window";
		[self.view addSubview:sample];
		
		season = [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x * 2, self.view.center.y, 150, 50)];
		season.textAlignment = NSTextAlignmentCenter;
		season.backgroundColor = [UIColor clearColor];
		season.font = [UIFont boldSystemFontOfSize:22.f];
		season.text = @"Fall Schedule";
		[self.view addSubview:season];
		
		[UIView animateWithDuration:0.5 animations:^{
			if(IS_IPAD){
				[season setCenter:CGPointMake(self.view.center.x, self.view.center.y - (self.view.frame.size.height * 1/4))];
				[sample setCenter:CGPointMake(self.view.center.x, self.view.center.y - (self.view.frame.size.height * 1/16))];
				[aboutView setCenter:CGPointMake(self.view.center.x, self.view.center.y + (self.view.frame.size.height * 1/4))];
			}
			
			else{
				[season setCenter:CGPointMake(self.view.center.x, mainBar.frame.size.height + (IS_WIDESCREEN?45:26))];
				[sample setCenter:CGPointMake(self.view.center.x, self.view.center.y - 65)];
				[aboutView setCenter:CGPointMake(self.view.center.x, self.view.frame.size.height - aboutView.frame.size.height/(IS_WIDESCREEN?2:2.35))];
			}
		}];
	}//end if
	
	else{
		mainCollectionView.scrollEnabled = YES;
		[UIView animateWithDuration:0.5 animations:^{
			[season setCenter:CGPointMake(self.view.center.x * 5, season.center.y)];
			[sample setCenter:CGPointMake(self.view.center.x * 5, sample.center.y)];
			[aboutView setCenter:CGPointMake(self.view.center.x * 5, aboutView.center.y)];
		} completion:^(BOOL finished){
			season = nil;
			sample = nil;
			aboutView = nil;
		}];
	}//end lese
}//end method

#pragma mark - Backend
-(void)createPlaces{
	NSMutableArray *working = [[NSMutableArray alloc] init];
	
	URPlace *blimpie = [[URPlace alloc] initWithName:@"Blimpie"];
	NSArray *blimpWeek = @[@"11.0-22.0"];
	blimpie.windows = @{@"1": blimpWeek, @"2": blimpWeek, @"3": blimpWeek, @"4": blimpWeek, @"5": blimpWeek, @"6": blimpWeek, @"7": blimpWeek};
	blimpie.location = @"43.128883333,-77.62975";
	[working addObject:blimpie];
	
	URPlace *connections = [[URPlace alloc] initWithName:@"Connections"];
	NSArray *cWeek = @[@"7.0-22.0"];
	connections.windows = @{@"1": @[@"14.0-22.0"], @"2": cWeek, @"3": cWeek, @"4": cWeek, @"5": cWeek, @"6": @[@"7.0-17.0"], @"7": @[@"sunday"]};
	connections.location = @"43.128766667,-77.628166667";
	[working addObject:connections];
	
	URPlace *danforth = [[URPlace alloc] initWithName:@"Danforth"];
	NSArray *danWeek = @[@"11.0-13.5", @"17.0-21.5"];
	NSArray *danEnd = @[@"8.0-10.5", @"10.5-14.0", @"14.0-17.0", @"17.0-21.0"];
	danforth.windows = @{@"1": danEnd, @"2": danWeek, @"3": danWeek, @"4": danWeek, @"5": danWeek, @"6": @[@"11.0-13.5", @"13.5-17.0", @"17.0-21.0"], @"7": danEnd};
	danforth.plan = URUnlimited;
	danforth.location = @"43.130033333,-77.626583333";
	[working addObject:danforth];
	
	URPlace *douglass = [[URPlace alloc] initWithName:@"Douglass"];
	NSArray *douWeek = @[@"7.5-11.0", @"11.0-14.5", @"14.5-17.0", @"17.0-20.0"];
	douglass.windows = @{@"1": @[@"monday"], @"2": douWeek, @"3": douWeek, @"4": douWeek, @"5": douWeek, @"6": @[@"7.5-11.0", @"11.0-14.0"], @"7": @[@"monday"]};
	douglass.plan = URUnlimited;
	douglass.location = @"43.128983333,-77.6291";
	[working addObject:douglass];
	
	URPlace *faculty = [[URPlace alloc] initWithName:@"Faculty Club"];
	NSArray *fWeek = @[@"11.0-14.0"];
	faculty.windows = @{@"1": @[@"monday"], @"2": fWeek, @"3": fWeek, @"4": fWeek, @"5": fWeek, @"6": fWeek, @"7": @[@"monday"]};
	faculty.location = @"43.1289,-77.628816667";
	[working addObject:faculty];

	URPlace *gg = [[URPlace alloc] initWithName:@"Grab & Go"];
	NSArray *ggWeek = @[@"10.5-14.0"];
	gg.windows = @{@"1": @[@"monday"], @"2": ggWeek, @"3": ggWeek, @"4": ggWeek, @"5": ggWeek, @"6": ggWeek, @"7": @[@"monday"]};
	gg.plan = URUnlimited;
	gg.location = @"43.1289,-77.628816667";
	[working addObject:gg];
	
	URPlace *hillside = [[URPlace alloc] initWithName:@"Hillside"];
	NSArray *hillWeek = @[@"7.5-3.0"];
	NSArray *hillEnd = @[@"12.0-3.0"];
	hillside.windows = @{@"1": hillEnd, @"2": hillWeek, @"3": hillWeek, @"4": hillWeek, @"5": hillWeek, @"6": hillWeek, @"7": hillEnd};
	hillside.location = @"43.129733333,-77.626433333";
	[working addObject:hillside];
	
	URPlace *pura = [[URPlace alloc] initWithName:@"Pura Vida"];
	NSArray *puraWeek = @[@"7.5-18.5"];
	pura.windows = @{@"1": @[@"monday"], @"2": puraWeek, @"3": puraWeek, @"4": puraWeek, @"5": puraWeek, @"6": @[@"7.5-14.0"], @"7": @[@"monday"]};
	pura.location = @"43.125333333,-77.629433333";
	[working addObject:pura];
	
	URPlace *starbucks = [[URPlace alloc] initWithName:@"Starbucks"];
	NSArray *starWeek = @[@"7.5-24.0"];
	starbucks.windows = @{@"1": @[@"10.0-24.0"], @"2": starWeek, @"3": starWeek, @"4": starWeek, @"5": starWeek, @"6": @[@"7.5-1"], @"7": @[@"10-1"]};
	starbucks.location = @"43.128883333,-77.62975";
	[working addObject:starbucks];
	
	URPlace *pit = [[URPlace alloc] initWithName:@"The Commons"];
	NSArray *pitWeek = @[@"8.5-24.0"];
	NSArray *pitEnd = @[@"11.0-24.0"];
	pit.windows = @{@"1": pitEnd, @"2": pitWeek, @"3": pitWeek, @"4": pitWeek, @"5": pitWeek, @"6": pitWeek, @"7": pitEnd};
	pit.location = @"43.128883333,-77.62975";
	[working addObject:pit];
		
	URPlace *mel = [[URPlace alloc] initWithName:@"The Mel"];
	NSArray *melWeek = @[@"11.0-14.0"];
	mel.windows = @{@"1": @[@"monday"], @"2": melWeek, @"3": melWeek, @"4": melWeek, @"5": melWeek, @"6": melWeek, @"7": @[@"monday"]};
	mel.location = @"43.1289,-77.628816667";
	[working addObject:mel];

	places = working;
	[self refreshPlaces];
}//end method

-(void)refreshPlaces{
	NSDate *now = [NSDate date];
	for(URPlace *p in places){
		[p refreshDates];
		
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
		dayComponent.day = -1;
		NSDate *yesterday = [calendar dateByAddingComponents:dayComponent toDate:now options:0];
		[p refreshDay:yesterday];
		
		if(![p openForDate:now])
			[p refreshDay:now];
	}
}//end method

-(void)refreshTime{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *comp = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
	NSMutableParagraphStyle *centered = [[NSMutableParagraphStyle alloc] init];
	[centered setAlignment:NSTextAlignmentCenter];
	
	titleText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
	titleText.backgroundColor = [UIColor clearColor];
	titleText.editable = NO;
	titleText.selectable = NO;
	NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithString:@"UROpen" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:16.f], NSParagraphStyleAttributeName : centered}];
	[titleStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n➟ %i:%@ %@", fmod(comp.hour, 12)==0?12:((int)fmod(comp.hour, 12)), [self appendZerosIfNeeded:comp.minute], comp.hour>=12?@"pm":@"am"] attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11.f], NSParagraphStyleAttributeName : centered}]];
	titleText.attributedText = titleStr;
	((UINavigationItem *)mainBar.items[0]).titleView = titleText;
}//end method

-(void)toggleBarButtonItems{
	UINavigationItem *buttons = (UINavigationItem *)mainBar.items[0];
	BOOL set = !buttons.leftBarButtonItem.enabled;
	for(UIBarButtonItem *b in buttons.leftBarButtonItems)
		[b setEnabled:set];
	[buttons.rightBarButtonItem setEnabled:set];
}//end method

-(void)enableBarButtonItems:(BOOL)should{
	UINavigationItem *buttons = (UINavigationItem *)mainBar.items[0];
	for(UIBarButtonItem *b in buttons.leftBarButtonItems)
		[b setEnabled:should];
	[buttons.rightBarButtonItem setEnabled:should];
}//end method

-(NSString *)appendZerosIfNeeded:(float)given{
	if(given - (int)given != 0.f || given == 0.f)
		return [NSString stringWithFormat:@"%i0", (int)given];
	else if(@((int)given).stringValue.length == 1)
		return [NSString stringWithFormat:@"0%i", (int)given];
	else
		return @((int)given).stringValue;
}//end method

#pragma mark - CollectionView
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [places count];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	
	if([((UILabel *)([[collectionView cellForItemAtIndexPath:indexPath] viewWithTag:2])).text isEqualToString:@"Name"])
		return;

	last = ((URPlace *)[places objectAtIndex:indexPath.row]);
	UIAlertView *mapAV = [[UIAlertView alloc] initWithTitle:last.name message:@"Would you like to view this dining hall in Apple Maps?" delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Ok", nil];
	[mapAV show];
}//end method

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	static NSString *cellIdentifier = @"URCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
	URPlace	*curr = [places objectAtIndex:indexPath.row];

	if(curr.plan == URCampus){
		((UIImageView *)[cell viewWithTag:1]).image = [UIImage imageNamed:@"URBlue.png"];
		((UIImageView *)[cell viewWithTag:1]).highlightedImage = [UIImage imageNamed:@"URBluePressed.png"];
		((UILabel *)[cell viewWithTag:3]).text = @"declining";
	}

	else{
		((UIImageView *)[cell viewWithTag:1]).image = [UIImage imageNamed:@"URGreen.png"];
		((UIImageView *)[cell viewWithTag:1]).highlightedImage = [UIImage imageNamed:@"URGreenPressed.png"];
		((UILabel *)[cell viewWithTag:3]).text = @"unlimited";
	}
	
	if(![curr openForDate:[NSDate date]])
		cell.alpha = 0.3;
	
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:2];
	titleLabel.adjustsFontSizeToFitWidth = YES;
	titleLabel.text = curr.name;
	
	UILabel *windowLabel = (UILabel *)[cell viewWithTag:4];
	windowLabel.text = [curr nextWindowForDate:[NSDate date]];
	
    return cell;
}//end method

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

#pragma mark - AlertView and ActionSheet
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if(buttonIndex != alertView.cancelButtonIndex){
		NSString *location = [@"http://maps.apple.com/?q=" stringByAppendingString:last.location];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:location]];
	}
}//end method

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
	if([title isEqualToString:@"Alphabetical"]){
		places = [places sortedArrayUsingSelector:@selector(nameCompare:)];
		[self reloadCollection];
	}
	
	else if([title isEqualToString:@"Meal Plan"]){
		places = [places sortedArrayUsingSelector:@selector(mealCompare:)];
		[self reloadCollection];
	}
	
	else if([title isEqualToString:@"Open Now"]){
		places = [places sortedArrayUsingSelector:@selector(openCompare:)];
		[self reloadCollection];
	}
}//end method

@end