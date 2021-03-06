//
//  GHAuthenticationManager.h
//  iGithub
//
//  Created by Oliver Letterer on 04.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHAPIUserV3.h"

extern NSString *const GHAPIAuthenticationManagerDidChangeAuthenticatedUserNotification;

@interface GHAPIAuthenticationManager : NSObject {
@private
    NSMutableArray *_usersArray;
    GHAPIUserV3 *_authenticatedUser;
}

- (void)addAuthenticatedUser:(GHAPIUserV3 *)user password:(NSString *)password;
- (void)removeAuthenticatedUser:(GHAPIUserV3 *)user;

@property (nonatomic, retain) GHAPIUserV3 *authenticatedUser;
@property (nonatomic, readonly) NSArray *usersArray;


@end


@interface GHAPIAuthenticationManager (Singleton)

+ (GHAPIAuthenticationManager *)sharedInstance;

@end

@interface GHAPIUserV3 (GHAPIAuthenticationManagerAdditions)

@property (nonatomic, copy) NSString *password;

@end
