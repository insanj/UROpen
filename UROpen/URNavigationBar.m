//
//  URNavigationBar.m
//  UROpen
//
//  Created by Julian Weiss on 12/1/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import "URNavigationBar.h"

@implementation URNavigationBar

-(id)initWithFrame:(CGRect)frame{
    if ((self = [super initWithFrame:frame])){
		//air
	}
	
    return self;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
	if(point.y <= 23.5 && !((URViewController *)self.window.rootViewController).tappedBall){
		UICollectionView *mainCollectionView = (UICollectionView *)[self.superview viewWithTag:5];
		[mainCollectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
	}

	return [super hitTest:point withEvent:event];
}//end method

@end