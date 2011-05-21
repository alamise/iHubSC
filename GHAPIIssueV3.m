//
//  GHAPIIssueV3.m
//  iGithub
//
//  Created by Oliver Letterer on 30.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHAPIIssueV3.h"
#import "GithubAPI.h"

@implementation GHAPIIssueV3

@synthesize assignee=_assignee, body=_body, closedAt=_closedAt, comments=_comments, createdAt=_createdAt, HTMLURL=_HTMLURL, labels=_labels, milestone=_milestone, number=_number, pullRequestID=_pullRequestID, state=_state, title=_title, updatedAt=_updatedAt, URL=_URL, user=_user;

#pragma mark - Initialization

- (id)initWithRawDictionary:(NSDictionary *)rawDictionay {
    if ((self = [super init])) {
        // Initialization code
        self.assignee = [[[GHAPIUserV3 alloc] initWithRawDictionary:[rawDictionay objectForKeyOrNilOnNullObject:@"assignee"] ] autorelease];
        self.body = [rawDictionay objectForKeyOrNilOnNullObject:@"body"];
        self.closedAt = [rawDictionay objectForKeyOrNilOnNullObject:@"closed_at"];
        self.comments = [rawDictionay objectForKeyOrNilOnNullObject:@"comments"];
        self.createdAt = [rawDictionay objectForKeyOrNilOnNullObject:@"created_at"];
        self.HTMLURL = [rawDictionay objectForKeyOrNilOnNullObject:@"html_url"];
        self.labels = [rawDictionay objectForKeyOrNilOnNullObject:@"labels"];
        self.number = [rawDictionay objectForKeyOrNilOnNullObject:@"number"];
        self.state = [rawDictionay objectForKeyOrNilOnNullObject:@"state"];
        self.title = [rawDictionay objectForKeyOrNilOnNullObject:@"title"];
        self.updatedAt = [rawDictionay objectForKeyOrNilOnNullObject:@"updated_at"];
        self.URL = [rawDictionay objectForKeyOrNilOnNullObject:@"url"];
        self.user = [[[GHAPIUserV3 alloc] initWithRawDictionary:[rawDictionay objectForKeyOrNilOnNullObject:@"user"] ] autorelease];
        
        self.milestone = [[[GHAPIMilestoneV3 alloc] initWithRawDictionary:[rawDictionay objectForKeyOrNilOnNullObject:@"milestone"] ] autorelease];
        NSString *htmlURL = [[rawDictionay objectForKeyOrNilOnNullObject:@"pull_request"] objectForKeyOrNilOnNullObject:@"html_url"];
        self.pullRequestID = [[htmlURL componentsSeparatedByString:@"/"] lastObject];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc {
    [_assignee release];
    [_body release];
    [_closedAt release];
    [_comments release];
    [_createdAt release];
    [_HTMLURL release];
    [_labels release];
    [_milestone release];
    [_number release];
    [_pullRequestID release];
    [_state release];
    [_title release];
    [_updatedAt release];
    [_URL release];
    [_user release];
    
    [super dealloc];
}

#pragma mark - class methods

+ (void)openedIssuesOnRepository:(NSString *)repository 
                            page:(NSInteger)page
               completionHandler:(void (^)(NSArray *issues, NSInteger nextPage, NSError *error))handler {
    
    // v3: GET /repos/:user/:repo/issues
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/issues?page=%d&per_page=100",
                                       [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], page ] ];
    
    [[GHBackgroundQueue sharedInstance] sendRequestToURL:URL setupHandler:nil completionHandler:^(id object, NSError *error, ASIFormDataRequest *request) {
        if (error) {
            handler(nil, 0, error);
        } else {
            NSArray *rawArray = object;
            
            NSMutableArray *finalArray = [NSMutableArray arrayWithCapacity:rawArray.count];
            for (NSDictionary *rawDictionary in rawArray) {
                [finalArray addObject:[[[GHAPIIssueV3 alloc] initWithRawDictionary:rawDictionary] autorelease] ];
            }
            
            NSString *linkHeader = [[request responseHeaders] objectForKey:@"Link"];
            
            handler(finalArray, linkHeader.nextPage, nil);
        }
    }];
}

+ (void)issueOnRepository:(NSString *)repository 
               withNumber:(NSNumber *)number 
        completionHandler:(void (^)(GHAPIIssueV3 *issue, NSError *error))handler {
    
    // v3: GET /repos/:user/:repo/issues/:id
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/issues/%@",
                                       [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                       number]];
    
    [[GHBackgroundQueue sharedInstance] sendRequestToURL:URL setupHandler:nil completionHandler:^(id object, NSError *error, ASIFormDataRequest *request) {
        if (error) {
            handler(nil, error);
        } else {
            handler([[[GHAPIIssueV3 alloc] initWithRawDictionary:object] autorelease], nil);
        }
    }];
}

+ (void)milestonesForIssueOnRepository:(NSString *)repository 
                            withNumber:(NSNumber *)number 
                                  page:(NSInteger)page
                     completionHandler:(void (^)(NSArray *milestones, NSInteger nextPage, NSError *error))handler {
    
    // v3: /repos/:user/:repo/milestones
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/milestones?page=%d&per_page=100",
                                       [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], page ] ];
    
    [[GHBackgroundQueue sharedInstance] sendRequestToURL:URL setupHandler:nil completionHandler:^(id object, NSError *error, ASIFormDataRequest *request) {
        if (error) {
            handler(nil, 0, error);
        } else {
            NSArray *rawArray = object;
            
            NSMutableArray *finalArray = [NSMutableArray arrayWithCapacity:rawArray.count];
            for (NSDictionary *rawDictionary in rawArray) {
                [finalArray addObject:[[[GHAPIMilestoneV3 alloc] initWithRawDictionary:rawDictionary] autorelease] ];
            }
            
            NSString *linkHeader = [[request responseHeaders] objectForKey:@"Link"];
            
            handler(finalArray, linkHeader.nextPage, nil);
        }
    }];
}

+ (void)createIssueOnRepository:(NSString *)repository 
                          title:(NSString *)title 
                           body:(NSString *)body 
                       assignee:(NSString *)assignee 
                      milestone:(NSNumber *)milestone 
              completionHandler:(void (^)(GHAPIIssueV3 *issue, NSError *error))handler {
    
    // v3: POST /repos/:user/:repo/issues
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/issues",
                                       [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ] ];
    
    [[GHBackgroundQueue sharedInstance] sendRequestToURL:URL 
                                            setupHandler:^(ASIFormDataRequest *request) {
                                                NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
                                                if (title) {
                                                    [jsonDictionary setObject:title forKey:@"title"];
                                                }
                                                if (body) {
                                                    [jsonDictionary setObject:body forKey:@"body"];
                                                }
                                                if (assignee) {
                                                    [jsonDictionary setObject:assignee forKey:@"assignee"];
                                                }
                                                if (milestone) {
                                                    [jsonDictionary setObject:milestone forKey:@"milestone"];
                                                }
                                                NSString *jsonString = [jsonDictionary JSONString];
                                                NSMutableData *jsonData = [[[jsonString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
                                                [request setPostBody:jsonData];
                                                [request setPostLength:[jsonString length] ];
                                            } 
                                       completionHandler:^(id object, NSError *error, ASIFormDataRequest *request) {
                                           if (error) {
                                               handler(nil, error);
                                           } else {
                                               NSDictionary *dictionary = object;
                                               handler([[[GHAPIIssueV3 alloc] initWithRawDictionary:dictionary ] autorelease], nil);
                                           }
                                       }];
}

+ (void)commentsForIssueOnRepository:(NSString *)repository 
                          withNumber:(NSNumber *)number 
                   completionHandler:(void (^)(NSArray *comments, NSError *error))handler {
    
    // v3: GET /repos/:user/:repo/issues/:id/comments
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/issues/%@/comments",
                                       [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], number ] ];
    
    
    [[GHBackgroundQueue sharedInstance] sendRequestToURL:URL setupHandler:nil completionHandler:^(id object, NSError *error, ASIFormDataRequest *request) {
        if (error) {
            handler(nil, error);
        } else {
            NSArray *rawCommentsArray = object;
            
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:rawCommentsArray.count];
            for (NSDictionary *rawDictionary in rawCommentsArray) {
                [array addObject:[[[GHAPIIssueCommentV3 alloc] initWithRawDictionary:rawDictionary] autorelease] ];
            }
            
            handler(array, nil);
        }
    }];
}

+ (void)postComment:(NSString *)comment forIssueOnRepository:(NSString *)repository 
         withNumber:(NSNumber *)number 
  completionHandler:(void (^)(GHAPIIssueCommentV3 *, NSError *))handler {
    
    // v3: POST /repos/:user/:repo/issues/:id/comments
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/issues/%@/comments",
                                       [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], number ] ];
    
    
    [[GHBackgroundQueue sharedInstance] sendRequestToURL:URL 
                                            setupHandler:^(ASIFormDataRequest *request) { 
                                                // {"body"=>"String"}
                                                NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObject:comment forKey:@"body"];
                                                NSString *jsonString = [jsonDictionary JSONString];
                                                NSMutableData *jsonData = [[[jsonString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
                                                [request setPostBody:jsonData];
                                                [request setPostLength:[jsonString length] ];
                                            } 
                                       completionHandler:^(id object, NSError *error, ASIFormDataRequest *request) {
                                           if (error) {
                                               handler(nil, error);
                                           } else {
                                               handler([[[GHAPIIssueCommentV3 alloc] initWithRawDictionary:object] autorelease], nil);
                                           }
                                       }];
}

@end
