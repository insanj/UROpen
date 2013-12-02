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

@interface URViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>{
	NSMutableArray *places;
	UIView *aboutView;
	NSTimer *global;
	URPlace *last;
	UIDynamicAnimator *animator;
	UITextView *titleText;
	BOOL info;
	UICollectionViewCell *sample;
}

@property (strong, nonatomic) UICollectionView *mainCollectionView;
@property (strong, nonatomic) URNavigationBar *mainBar;
@end