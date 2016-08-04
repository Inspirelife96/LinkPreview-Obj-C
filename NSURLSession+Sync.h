//
//  NSURLSession+Sync.h
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 03.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (Sync)
- (NSData *)synchronousDataTaskWithURL:(NSURL *)url;
@end
