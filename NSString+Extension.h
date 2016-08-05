//
//  NSString+Extension.h
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 03.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

@import Foundation;

@interface NSString (Extension)
- (NSString *)trim;
// Remove extra white spaces
- (NSString *)extendedTrim;
// Decode HTML entities
- (NSString *)decoded;
// Strip tags
- (NSString *)tagsStripped;
- (NSString *)deleteTagByPattern:(NSString *)pattern;
// Replace
- (NSString *)replaceSearchString:(NSString *)search withString:(NSString *)with;
// Substring
- (NSString *)substringStart:(NSUInteger)start end:(NSUInteger)end;
// Check if it's a valid url
- (BOOL)isValidURL;
- (BOOL)isImage;
@end
