//
//  NSString+Extension.m
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 03.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

#import "NSString+Extension.h"
#import "FCRegex.h"
@import UIKit;


@implementation NSString (Extension)

- (NSString *)trim {
    return [self stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

// Remove extra white spaces
- (NSString *)extendedTrim {
    NSArray *components = [self componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return [[[components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString  *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        return evaluatedObject.length > 0;
    }]] componentsJoinedByString:@" "] trim];
}

// Decode HTML entities
- (NSString *)decoded {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                 documentAttributes:nil error:nil];
    return attributedString.string ? : self;
}

// Strip tags
- (NSString *)tagsStripped {
    return [self deleteTagByPattern:rawTagPattern];
}

- (NSString *)deleteTagByPattern:(NSString *)pattern {
    return [self stringByReplacingOccurrencesOfString:pattern withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
}

// Replace
- (NSString *)replaceSearchString:(NSString *)search withString:(NSString *)with {
    return [self stringByReplacingOccurrencesOfString:search withString:with];
}

// Substring
- (NSString *)substringStart:(NSUInteger)start end:(NSUInteger)end{
    return [self substringWithRange:NSMakeRange(start, end)];
}

// Check if it's a valid url
- (BOOL)isValidURL {
    return [FCRegex testString:self regex:rawUrlPattern];
}

- (BOOL)isImage {
    return [FCRegex testString:self regex:imagePattern];
}

@end
