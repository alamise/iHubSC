//
//  ANNotificationQueueRootViewController.m
//  iGithub
//
//  Created by Oliver Letterer on 02.08.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "ANNotificationQueueRootViewController.h"

@implementation ANNotificationQueueRootViewController

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if (UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM()) {
        return UIInterfaceOrientationPortrait == interfaceOrientation;
    }
	return YES;
}

@end
