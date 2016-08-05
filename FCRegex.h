//
//  FCRegex.h
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 03.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString * const imagePattern;
extern NSString * const imageTagPattern;
extern NSString * const titlePattern;
extern NSString * const metatagPattern;
extern NSString * const metatagContentPattern;
extern NSString * const cannonicalUrlPattern;
extern NSString * const rawUrlPattern;
extern NSString * const rawTagPattern;
extern NSString * const inlineStylePattern;
extern NSString * const inlineScriptPattern;
extern NSString * const linkPattern;
extern NSString * const scriptPattern;
extern NSString * const commentPattern;

@interface FCRegex : NSObject
+ (BOOL)testString:(NSString *)string regex:(NSString *)regex;

// Match first occurrency
+ (NSString *)pregMatchFirstString:(NSString *)string regex:(NSString *)regex index:(NSUInteger)index;

// Match all occurrencies
+ (NSArray<NSString *> *)pregMatchAllString:(NSString *)string regex:(NSString *)regex index:(NSUInteger)index;

// Extract matches from string
+ (NSArray<NSString *> *)stringMatchesResults:(NSArray *)results text:(NSString *)text index:(NSUInteger)index;

// Return tag pattern
+ (NSString *)tagPattern:(NSString *)tag;
@end
