//
//  GHAPIGistCommentV3.h
//  iGithub
//
//  Created by Oliver Letterer on 05.05.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GHAPIUserV3;

@interface GHAPIGistCommentV3 : NSObject <NSCoding> {
@private
    NSNumber *_ID;
    NSString *_URL;
    NSString *_body;
    GHAPIUserV3 *_user;
    NSString *_createdAt;
    
    NSAttributedString *_attributedBody;
    NSAttributedString *_selectedAttributedBody;
}

@property (nonatomic, copy) NSNumber *ID;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, retain) GHAPIUserV3 *user;
@property (nonatomic, copy) NSString *createdAt;

@property (nonatomic, retain) NSAttributedString *attributedBody;
@property (nonatomic, retain) NSAttributedString *selectedAttributedBody;

- (id)initWithRawDictionary:(NSDictionary *)rawDictionary;

@end
