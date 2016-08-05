//
//  FCLinkPreview.m
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 04.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

#import "FCLinkPreview.h"
#import "NSString+Extension.h"
#import "FCRegex.h"
static const NSUInteger titleMinimumRelevant = 3;
static const NSUInteger decriptionMinimumRelevant = 5;

@interface FCLinkPreview()
@property (nonatomic,strong) NSURL *url;
@property (nonatomic,strong) NSURLSessionDataTask *task;
@property (nonatomic,strong) NSURLSession *session;
@end

@implementation FCLinkPreview
- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _session = [NSURLSession sharedSession];
    }
    return self;
}

- (void)previewWithText:(NSString *)text  onSuccess:(void (^)(NSMutableDictionary *result))success
                onError:(void (^)(NSNumber *errorCode, NSString *desc))failure {
    [self resetResult];
    self.text = text;
    NSURL *url = [self extractURL];
    if (url != nil) {
        self.url = url;
        self.result[@"url"] = url.absoluteString;
        __weak typeof(self) weakSelf = self;
        [self unshortenURL:url completion:^(NSURL *unshortened) {
            weakSelf.result[@"finalUrl"] = unshortened;
            weakSelf.result[@"canonicalUrl"] = [weakSelf extractCanonicalURL:unshortened];
            [weakSelf extractInfoOnSuccessBlock:success onErrorBlock:failure];
        }];
    } else if(failure != nil) {
        failure(@(FCLinkPreviewErrorNoURLHasBeenFound),self.text);
    }
}

// Reset data on result
- (void)resetResult {
    self.result = [@{@"url":@"", @"finalUrl":@"", @"canonicalUrl":@"", @"title":@"",
                     @"description":@"", @"images":[NSArray new], @"image":@""} mutableCopy];
}

- (void)fillRemainingInfo:(NSString *)title description:(NSString *)description images:(NSArray *)images image:(NSString *)image {
    self.result[@"title"] = title;
    self.result[@"description"] = description;
    self.result[@"images"] = images;
    self.result[@"image"] = image;
}

- (void)cancel {
    [self.task cancel];
}

// Extract first URL from text
- (NSURL *)extractURL {
    NSArray *pieces = [[self.text componentsSeparatedByString:@" "] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary<NSString *,id> * bindings) {
        return [evaluatedObject isValidURL];
    }]];
   
    NSURL *url = nil;
    if (pieces.count > 0) {
         NSString *piece = pieces[0];
        url = [NSURL URLWithString:piece];
    }
    return url;
}

// Unshorten URL by following redirections
- (void)unshortenURL:(NSURL *)url completion:(void (^)(NSURL *unshortened))completion {
    __weak typeof(self) weakSelf = self;
    self.task = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSURL *finalResult = response.URL;
        if (finalResult != nil) {
            if ([finalResult.absoluteString isEqualToString:url.absoluteString]) {
                if (completion != nil) {
                    completion(url);
                }
            } else {
                [weakSelf cancel];
                [weakSelf unshortenURL:finalResult completion:completion];
            }
        } else {
            if (completion != nil) {
                completion(url);
            }
        }
    }];
    [self.task resume];
}

// Extract base URL
- (NSString *)extractBaseUrl:(NSString *)url {
    NSRange slash = [url rangeOfString:@"/"];
    if (slash.location != NSNotFound) {
        url = [url substringStart:0 end:slash.length>1 ? slash.length - 1 : 0];
    }
    return url;
    
}

// Extract canonical URL

- (NSString *)extractCanonicalURL:(NSURL *)finalUrl {
    NSString *preUrl = finalUrl.absoluteString;
    NSString *url = [[[[preUrl replaceSearchString:@"http://" withString:@""] replaceSearchString:@"https://" withString:@""]
                     replaceSearchString:@"file://" withString:@""] replaceSearchString:@"ftp://" withString:@""];
    if (![preUrl isEqualToString:url]) {
        NSString *canonicalUrl = [FCRegex pregMatchFirstString:url regex:cannonicalUrlPattern index:1];
        if (canonicalUrl != nil) {
            if (![canonicalUrl isEqualToString:@""]) {
                return [self extractBaseUrl:canonicalUrl];
            } else {
                return [self extractBaseUrl:url];
            }
        } else {
            return [self extractBaseUrl:url];
        }
    } else {
        return [self extractBaseUrl:preUrl];
    }
}

// Extract HTML code and the information contained on it
- (void)extractInfoOnSuccessBlock:(void(^)(NSMutableDictionary *result))completion onErrorBlock:(void(^)(NSNumber *errorCode, NSString *desc))onError {
    NSURL *url = self.result[@"finalUrl"];
    if (url != nil) {
        if (url.absoluteString.isImage) {
            [self fillRemainingInfo:@"" description:@"" images:@[url.absoluteString] image:url.absoluteString];
             if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(self.result);
                });
             }
        } else {
            NSURL *sourceUrl = ([url.absoluteString hasPrefix:@"http://"] || [url.absoluteString hasPrefix:@"https://"])
                                                ? url : [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",url]];
            
            NSError *error = nil;
            NSStringEncoding encoding;
            
            __block NSString *source = [[NSString stringWithContentsOfURL:sourceUrl usedEncoding:&encoding error:&error] extendedTrim];
            if (error == nil) {
                source = [self cleanSource:source];
                [self performPageCrawling:source];
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(self.result);
                    });
               }
            } else {
                NSMutableArray *arrayOfEncodings = [[NSMutableArray alloc] initWithObjects:@(encoding), nil];
                const NSStringEncoding *encodings = [NSString availableStringEncodings];
                while (*encodings != 0){
                    [arrayOfEncodings addObject:[NSNumber numberWithUnsignedLong:*encodings]];
                    encodings++;
                }
                [self tryAnotherEnconding:sourceUrl encodingArray:arrayOfEncodings completion:completion onErrorBlock:onError];
            }
        }
    } else {
        [self fillRemainingInfo:@"" description:@"" images:@[] image:@""];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self.result);
            });
        }
    }
}

// Removing unnecessary data from the source
- (NSString *)cleanSource:(NSString *)source {
    source = [source deleteTagByPattern:inlineStylePattern];
    source = [source deleteTagByPattern:inlineScriptPattern];
    source = [source deleteTagByPattern:linkPattern];
    source = [source deleteTagByPattern:scriptPattern];
    source = [source deleteTagByPattern:commentPattern];
    return source;
}

// Try to get the page using another available encoding instead the page's own encoding
- (void)tryAnotherEnconding:(NSURL *)sourceUrl encodingArray:(NSArray *)encodingArray completion:(void(^)(NSMutableDictionary *result))completion onErrorBlock:(void(^)(NSNumber *errorCode, NSString *desc))onError {
    if ([encodingArray count] == 0) {
        if (onError != nil) {
            onError(@(FCLinkPreviewErrorParseError),self.url.absoluteString);
        }
    } else {
        NSError *error = nil;
         NSStringEncoding firstEncoding = (NSStringEncoding) [((NSNumber *) encodingArray[0]) intValue];
        __block NSString *source = [[NSString stringWithContentsOfURL:sourceUrl encoding:firstEncoding error:&error] extendedTrim];
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                source = [self cleanSource:source];
                [self performPageCrawling:source];
                if (completion) {
                    completion(self.result);
                }
            });
        } else {
            NSNumber *firstEncoding = encodingArray[0];
            encodingArray = [encodingArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNumber *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
                return ![evaluatedObject isEqualToNumber:firstEncoding];
            }]];
            [self tryAnotherEnconding:sourceUrl encodingArray:encodingArray completion:completion onErrorBlock:onError];
        }
    }
}

// Perform the page crawiling
- (void)performPageCrawling:(NSString *)htmlCode {
    [self crawlMetaTags:htmlCode];
    htmlCode = [self crawlTitle:htmlCode];
    htmlCode = [self crawlDescription:htmlCode];
    [self crawlImages:htmlCode];
}

// Search for meta tags
- (void)crawlMetaTags:(NSString *)htmlCode {
    NSArray *possibleTags = @[@"title", @"description", @"image"];
    NSArray<NSString *> *metatags = [FCRegex pregMatchAllString:htmlCode regex:metatagPattern index:1];
    [metatags enumerateObjectsUsingBlock:^(NSString *metatag, NSUInteger idx, BOOL *stop) {
        for (NSString *tag in possibleTags) {
            if ([metatag rangeOfString:[NSString stringWithFormat:@"property=\"og:%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"property='og:%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"name=\"twitter:%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"name='twitter:%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"name=\"%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"name='%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"itemprop=\"%@",tag]].location != NSNotFound ||
                [metatag rangeOfString:[NSString stringWithFormat:@"itemprop='%@",tag]].location != NSNotFound) {
                NSString *tmp = self.result[tag];
                if (tmp.length == 0) {
                    NSString *value = [FCRegex pregMatchFirstString:metatag regex:metatagContentPattern index:2];
                    if (value != nil) {
                        value = [[value decoded] extendedTrim];
                        self.result[tag] = [tag isEqualToString:@"image"] ? [self addImagePrefixIfNeeded:value]: value;
                    }
                }
                
            }
        }
    }];
}

// Add prefix image if needed
- (NSString *)addImagePrefixIfNeeded:(NSString *)image {
    NSString *canonicalUrl = self.result[@"canonicalUrl"];
    if (canonicalUrl.length > 0) {
        if ([image hasPrefix:@"//"]) {
            image = [NSString stringWithFormat:@"http:%@",image];
        } else if ([image hasPrefix:@"/"]) {
            image = [NSString stringWithFormat:@"http://%@%@",canonicalUrl,image];
        }
    }
    return image;
}

// Crawl for title if needed
- (NSString *)crawlTitle:(NSString *)htmlCode {
    NSString *title = self.result[@"title"];
    if (title.length == 0) {
         NSString *value = [FCRegex pregMatchFirstString:htmlCode regex:titlePattern index:2];
        if (value.length == 0) {
            NSString *fromBody = nil;
            fromBody = [self crawlCode:htmlCode minimum:titleMinimumRelevant];
            if (fromBody.length != 0) {
                self.result[@"title"] = [[fromBody decoded] extendedTrim];
                return [htmlCode replaceSearchString:fromBody withString:@""];
            }
        } else {
            self.result[@"title"] = [[value decoded] extendedTrim];
        }
    }
    return htmlCode;
}

// Crawl the entire code
- (NSString *)crawlCode:(NSString *)content minimum:(NSUInteger)minimum {
    NSString *resultFirstSearch = [self getTagContent:@"p" content:content minimum:minimum];
    if (resultFirstSearch.length > 0) {
        return resultFirstSearch;
    } else {
        NSString *resultSecondSearch = [self getTagContent:@"div" content:content minimum:minimum];
        if (resultSecondSearch.length > 0) {
            return resultSecondSearch;
        } else {
            NSString *resultThirdSearch = [self getTagContent:@"span" content:content minimum:minimum];
            if (resultThirdSearch.length > 0) {
                return resultThirdSearch;
            } else {
                if (resultThirdSearch.length >= resultFirstSearch.length) {
                    if (resultThirdSearch.length >= resultSecondSearch.length) {
                        return resultThirdSearch;
                    } else {
                        return resultSecondSearch;
                    }
                } else {
                    return resultFirstSearch;
                }
            }
        }
    }
}

// Get tag content
- (NSString *)getTagContent:(NSString *)tag content:(NSString *)content minimum:(NSUInteger)minimum {
    NSString *pattern = [FCRegex tagPattern:tag];
    NSArray<NSString *> *rawMatches = [FCRegex pregMatchAllString:content regex:pattern index:2];
    NSArray<NSString *> *matches = [rawMatches filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString * evaluatedObject, NSDictionary<NSString *,id> * bindings) {
        return [[evaluatedObject extendedTrim] tagsStripped].length >= minimum;
    }]];
    NSString *result = matches.count > 0 ? matches[0] : @"";
    if (result.length == 0) {
        NSString *match = [FCRegex pregMatchFirstString:content regex:pattern index:2];
        result = [[match extendedTrim] tagsStripped];
    }
    return result;
}


// Crawl for description if needed
- (NSString *)crawlDescription:(NSString *)htmlCode {
    NSString *description = self.result[@"description"];
    if (description.length == 0) {
        NSString *value = [self crawlCode:htmlCode minimum:decriptionMinimumRelevant];
        if (value.length > 0) {
            self.result[@"description"] = [[value decoded] extendedTrim];
        }
    }
    return htmlCode;
}

// Crawl for images
- (void)crawlImages:(NSString *)htmlCode {
     NSString *mainImage = self.result[@"image"];
    if (mainImage.length == 0) {
        NSArray<NSString *> *images = self.result[@"images"];
        if (images.count == 0) {
            NSArray<NSString *> *values = [FCRegex pregMatchAllString:htmlCode regex:imageTagPattern index:2];
            NSMutableArray *imgs = [NSMutableArray arrayWithCapacity:values.count];
            [values enumerateObjectsUsingBlock:^(NSString *value, NSUInteger idx, BOOL *stop) {
                if ([value extendedTrim].length > 0 && ![value hasPrefix:@"https://"] && ![value hasPrefix:@"http://"] && ![value hasPrefix:@"ftp://"]) {
                    NSURL *host = self.result[@"finalUrl"];
                    if ([value hasPrefix:@"//"]) {
                        value = [NSString stringWithFormat:@"%@:%@",host.scheme,value];
                    }
                    else {
                        value = [NSString stringWithFormat:@"%@://%@%@",host.scheme,host,value];
                    }
                    [imgs addObject:value];
                }
            }];
            self.result[@"images"] = imgs;
            if (imgs.count > 0) {
                self.result[@"image"] = imgs[0];
            }
        }
    } else {
        self.result[@"images"] = @[[self addImagePrefixIfNeeded:mainImage]];
    }
}

@end
