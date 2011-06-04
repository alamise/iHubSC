//
//  GHBackgroundQueue.h
//  iGithub
//
//  Created by Oliver Letterer on 29.03.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "ASIFormDataRequest.h"

dispatch_queue_t GHAPIBackgroundQueue();

@interface GHBackgroundQueue : NSObject {
    dispatch_queue_t _backgroundQueue;
    NSUInteger _remainingAPICalls;
}

@property (nonatomic, readonly) dispatch_queue_t backgroundQueue;
@property (nonatomic, readonly) NSUInteger remainingAPICalls;

- (void)sendRequestToURL:(NSURL *)URL setupHandler:(void(^)(ASIFormDataRequest *request))setupHandler completionHandler:(void(^)(id object, NSError *error, ASIFormDataRequest *request))completionHandler;

@end


@interface GHBackgroundQueue (Singleton)

+ (GHBackgroundQueue *)sharedInstance;

@end
