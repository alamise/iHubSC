//
//  GHPullRequest.m
//  iGithub
//
//  Created by Oliver Letterer on 01.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "GHPullRequest.h"
#import "GithubAPI.h"

@implementation GHPullRequest

@synthesize additions=_additions, commits=_commits, deletions=_deletions, ID=_ID, issueID=_issueID, number=_number, title=_title;

#pragma mark - Initialization

- (id)initWithRawDictionary:(NSDictionary *)rawDictionary {
    GHAPIObjectExpectedClass(&rawDictionary, NSDictionary.class);
    if ((self = [super init])) {
        // Initialization code
        self.additions = [rawDictionary objectForKeyOrNilOnNullObject:@"additions"];
        self.commits = [rawDictionary objectForKeyOrNilOnNullObject:@"commits"];
        self.deletions = [rawDictionary objectForKeyOrNilOnNullObject:@"deletions"];
        self.ID = [rawDictionary objectForKeyOrNilOnNullObject:@"id"];
        self.issueID = [rawDictionary objectForKeyOrNilOnNullObject:@"issue_id"];
        self.number = [rawDictionary objectForKeyOrNilOnNullObject:@"number"];
        self.title = [rawDictionary objectForKeyOrNilOnNullObject:@"title"];
    }
    return self;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.additions forKey:@"additions"];
    [aCoder encodeObject:self.commits forKey:@"commits"];
    [aCoder encodeObject:self.deletions forKey:@"deletions"];
    [aCoder encodeObject:self.ID forKey:@"ID"];
    [aCoder encodeObject:self.issueID forKey:@"issueID"];
    [aCoder encodeObject:self.number forKey:@"number"];
    [aCoder encodeObject:self.title forKey:@"title"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.additions = [aDecoder decodeObjectForKey:@"additions"];
        self.commits = [aDecoder decodeObjectForKey:@"commits"];
        self.deletions = [aDecoder decodeObjectForKey:@"deletions"];
        self.ID = [aDecoder decodeObjectForKey:@"ID"];
        self.issueID = [aDecoder decodeObjectForKey:@"issueID"];
        self.number = [aDecoder decodeObjectForKey:@"number"];
        self.title = [aDecoder decodeObjectForKey:@"title"];
    }
    return self;
}

#pragma mark - Class methods

+ (void)pullRequestDiscussionOnRepository:(NSString *)repository 
                                   number:(NSNumber *)number 
                        completionHandler:(void(^)(GHPullRequestDiscussion *discussion, NSError *error))handler {
    
    dispatch_async(GHAPIBackgroundQueue(), ^(void) {
        
        // /pulls/:user/:repo/:number
        
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/api/v2/json/pulls/%@/%@",
                                           [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                           number] ];
        
        NSError *myError = nil;
        
        ASIFormDataRequest *request = [ASIFormDataRequest authenticatedFormDataRequestWithURL:URL];
        [request startSynchronous];
        
        myError = [request error];
        
        if (!myError) {
            myError = [NSError errorFromRawDictionary:[[request responseString] objectFromJSONString] ];
        }
        
        NSString *jsonString = [request responseString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (myError) {
                handler(nil, myError);
            } else {
                id object = jsonString.objectFromJSONString;
                NSDictionary *dictionary = GHAPIObjectExpectedClass(&object, NSDictionary.class);
                
                handler([[GHPullRequestDiscussion alloc] initWithRawDictionary:[dictionary objectForKey:@"pull"]], nil);
            }
        });
    });
}

+ (void)pullRequestsOnRepository:(NSString *)repository 
               completionHandler:(void (^)(NSArray *, NSError *))handler {
    
    dispatch_async(GHAPIBackgroundQueue(), ^(void) {
        
        // /pulls/:user/:repo/:state
        
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/api/v2/json/pulls/%@/open",
                                           [repository stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] ];
        
        NSError *myError = nil;
        
        ASIHTTPRequest *request = [ASIHTTPRequest authenticatedFormDataRequestWithURL:URL];
        [request startSynchronous];
        
        myError = [request error];
        
        if (!myError) {
            myError = [NSError errorFromRawDictionary:[[request responseString] objectFromJSONString] ];
        }
        
        NSString *jsonString = [request responseString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (myError) {
                handler(nil, myError);
            } else {
                id object = [jsonString objectFromJSONString];
                NSDictionary *dictionary = GHAPIObjectExpectedClass(&object, NSDictionary.class);
                id pullss = [dictionary objectForKeyOrNilOnNullObject:@"pulls"];
                NSArray *rawPulls = GHAPIObjectExpectedClass(&pullss, NSArray.class);
                NSMutableArray *pulls = [NSMutableArray arrayWithCapacity:[rawPulls count] ];
                
                for (NSDictionary *rawPullDiscussion in rawPulls) {
                    [pulls addObject:[[GHPullRequestDiscussion alloc] initWithRawDictionary:rawPullDiscussion] ];
                }
                handler(pulls, nil);
            }
        });
    });
    
}

#pragma mark - Memory management


@end
