//
//  GHAPIIssueV3.h
//  iGithub
//
//  Created by Oliver Letterer on 30.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHAPIConnectionHandlersV3.h"

extern NSString *const GHAPIIssueV3ContentChangedNotification;
extern NSString *const GHAPIIssueV3CreationNotification;



@class GHAPIUserV3, GHAPIMilestoneV3, GHAPIIssueCommentV3;

extern NSString *const kGHAPIIssueStateV3Open;
extern NSString *const kGHAPIIssueStateV3Closed;

@interface GHAPIIssueV3 : NSObject <NSCoding> {
@private
    GHAPIUserV3 *_assignee;
    NSString *_body;
    NSString *_closedAt;
    NSNumber *_comments;
    NSString *_createdAt;
    NSString *_HTMLURL;
    NSArray *_labels;
    GHAPIMilestoneV3 *_milestone;
    NSNumber *_number;
    NSNumber *_pullRequestID;
    NSString *_state;
    NSString *_title;
    NSString *_updatedAt;
    NSString *_URL;
    GHAPIUserV3 *_user;
    
    NSString *_repository;
    NSAttributedString *_attributedBody;
    NSAttributedString *_selectedAttributedBody;
}

@property (nonatomic, retain) GHAPIUserV3 *assignee;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *closedAt;
@property (nonatomic, copy) NSNumber *comments;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, copy) NSString *HTMLURL;
@property (nonatomic, copy) NSArray *labels;
@property (nonatomic, retain) GHAPIMilestoneV3 *milestone;
@property (nonatomic, copy) NSNumber *number;
@property (nonatomic, copy) NSNumber *pullRequestID;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *updatedAt;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, retain) GHAPIUserV3 *user;
@property (nonatomic, copy) NSString *repository;
@property (nonatomic, retain) NSAttributedString *attributedBody;
@property (nonatomic, retain) NSAttributedString *selectedAttributedBody;

@property (nonatomic, readonly) BOOL isPullRequest;
@property (nonatomic, readonly) BOOL hasAssignee;
@property (nonatomic, readonly) BOOL hasMilestone;
@property (nonatomic, readonly) BOOL isOpen;

- (BOOL)matchedString:(NSString *)string;

- (BOOL)isEqualToIssue:(GHAPIIssueV3 *)issue;

- (id)initWithRawDictionary:(NSDictionary *)rawDictionary;

+ (void)openedIssuesOnRepository:(NSString *)repository page:(NSInteger)page completionHandler:(GHAPIPaginationHandler)handler;

+ (void)issueOnRepository:(NSString *)repository 
               withNumber:(NSNumber *)number 
        completionHandler:(void (^)(GHAPIIssueV3 *issue, NSError *error))handler;

+ (void)updateIssueOnRepository:(NSString *)repository 
                     withNumber:(NSNumber *)number 
                          title:(NSString *)title 
                           body:(NSString *)body 
                       assignee:(NSString *)assignee 
                          state:(NSString *)state 
                      milestone:(NSNumber *)milestone 
                         labels:(NSArray *)labels 
              completionHandler:(void (^)(GHAPIIssueV3 *issue, NSError *error))handler;

+ (void)replaceLabelOfIssueOnRepository:(NSString *)repository 
                                 number:(NSNumber *)number withLabels:(NSArray *)labels completionHandler:(GHAPIErrorHandler)handler;

+ (void)milestonesForIssueOnRepository:(NSString *)repository 
                            withNumber:(NSNumber *)number 
                                  page:(NSInteger)page
                     completionHandler:(GHAPIPaginationHandler)handler;

+ (void)createIssueOnRepository:(NSString *)repository 
                          title:(NSString *)title 
                           body:(NSString *)body 
                       assignee:(NSString *)assignee 
                      milestone:(NSNumber *)milestone 
                         labels:(NSArray *)labels 
              completionHandler:(void (^)(GHAPIIssueV3 *issue, NSError *error))handler;

+ (void)commentsForIssueOnRepository:(NSString *)repository 
                          withNumber:(NSNumber *)number 
                   completionHandler:(void (^)(NSArray *comments, NSError *error))handler;

+ (void)postComment:(NSString *)comment forIssueOnRepository:(NSString *)repository 
         withNumber:(NSNumber *)number 
  completionHandler:(void (^)(GHAPIIssueCommentV3 *comment, NSError *error))handler;

+ (void)closeIssueOnRepository:(NSString *)repository 
                    withNumber:(NSNumber *)number 
             completionHandler:(void (^)(NSError *error))handler;

+ (void)reopenIssueOnRepository:(NSString *)repository 
                     withNumber:(NSNumber *)number 
              completionHandler:(void (^)(NSError *error))handler;

+ (void)eventforIssueWithID:(NSNumber *)issueID OnRepository:(NSString *)repository 
          completionHandler:(void (^)(NSArray *events, NSError *error))handler;

// history will contain GHAPIIssueEventV3's and GHAPIIssueCommentV3's
+ (void)historyForIssueWithID:(NSNumber *)issueID onRepository:(NSString *)repository 
            completionHandler:(void (^)(NSMutableArray *history, NSError *error))handler;

+ (void)issuesOnRepository:(NSString *)repository 
                 milestone:(NSNumber *)milestone 
                    labels:(NSArray *)labels
                     state:(NSString *)state 
                      page:(NSInteger)page
         completionHandler:(GHAPIPaginationHandler)handler;

+ (void)issuesOfAuthenticatedUserOnPage:(NSInteger)page completionHandler:(GHAPIPaginationHandler)handler;

+ (void)allIssuesOfAuthenticatedUserWithCompletionHandler:(void (^)(NSMutableArray *issues, NSError *error))handler;
+ (void)_dumpIssuesOfAuthenticatedUserInArray:(NSMutableArray *)issuesArray page:(NSUInteger)page completionHandler:(GHAPIErrorHandler)handler;

@end
