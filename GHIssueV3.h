//
//  GHIssueV3.h
//  iGithub
//
//  Created by Oliver Letterer on 30.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GHUser, GHMilestone;

@interface GHIssueV3 : NSObject {
@private
    GHUser *_assignee;
    NSString *_body;
    NSString *_closedAt;
    NSNumber *_comments;
    NSString *_createdAt;
    NSString *_HTMLURL;
    NSArray *_labels;
    GHMilestone *_milestone;
    NSNumber *_number;
    NSNumber *_pullRequestID;
    NSString *_state;
    NSString *_title;
    NSString *_updatedAt;
    NSString *_URL;
    GHUser *_user;
}

@property (nonatomic, retain) GHUser *assignee;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *closedAt;
@property (nonatomic, copy) NSNumber *comments;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, copy) NSString *HTMLURL;
@property (nonatomic, copy) NSArray *labels;
@property (nonatomic, retain) GHMilestone *milestone;
@property (nonatomic, copy) NSNumber *number;
@property (nonatomic, copy) NSNumber *pullRequestID;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *updatedAt;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, retain) GHUser *user;

- (id)initWithRawDictionary:(NSDictionary *)rawDictionay;


+ (void)openedIssuesOnRepository:(NSString *)repository 
                            page:(NSInteger)page
               completionHandler:(void (^)(NSArray *issues, NSInteger nextPage, NSError *error))handler;


@end
