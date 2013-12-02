//
//  URAppDelegate.h
//  UROpen
//
//  Created by Julian Weiss on 11/30/13.
//  Copyright (c) 2013 insanj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URViewController.h"

@interface URAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) URViewController *viewController;

@end