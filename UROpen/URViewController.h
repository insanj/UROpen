//
//  URViewController.h
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URPlace.h"
#import "URNavigationBar.h"

@interface URViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate>{
	NSArray *places;
	NSDictionary *descriptions;
	URPlace *last;

	UITextView *titleText;
	UIDynamicAnimator *animator;
	UIView *aboutView;
	UICollectionViewCell *sample;
	UILabel *season;
	
	CGPoint ballCenter;
	float prevAlpha;
	
	NSTimer *timer;
}

@property (strong, nonatomic) UICollectionView *mainCollectionView;
@property (strong, nonatomic) UINavigationBar *mainBar;
@property (strong, nonatomic) UICollectionViewCell *tappedBall;
@end