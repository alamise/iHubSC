//
//  NSString+GithubAPIAdditions.h
//  iGithub
//
//  Created by Oliver Letterer on 05.04.11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (GHAPIDateFormatting)
@property (nonatomic, readonly) NSDate *dateFromGithubAPIDateString;
@property (nonatomic, readonly) NSString *gravarID;
@property (nonatomic, readonly) NSString *prettyTimeIntervalSinceNow;
@property (nonatomic, readonly) NSString *prettyShortTimeIntervalSinceNow;
@end



@interface NSString (GHAPIHTTPParsing)
@property (nonatomic, readonly) NSUInteger nextPage;
@end



@interface NSString (GHAPIColorParsing)
@property (nonatomic, readonly) UIColor *colorFromAPIColorString;
@end



@interface NSString (Parsing)
- (NSString *)substringBetweenLeftBounds:(NSString *)leftBounds andRightBounds:(NSString *)rightBounds;
@end



@interface NSString (GHMarkdownParsing)
@property (nonatomic, readonly) NSAttributedString *nonSelectedAttributesStringFromMarkdown;
@property (nonatomic, readonly) NSAttributedString *selectedAttributesStringFromMarkdown;
@end



@interface NSString (GHAPIHasing)
- (NSString *)stringFromMD5Hash;
@end

