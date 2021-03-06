//
//  GHPPullRequestsViewController.h
//  iGithub
//
//  Created by Oliver Letterer on 07.07.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GHPDataArrayViewController.h"

@interface GHPPullRequestsViewController : GHPDataArrayViewController {
@private
    NSString *_repository;
}

@property (nonatomic, copy) NSString *repository;

- (id)initWithRepository:(NSString *)repository;

@end
