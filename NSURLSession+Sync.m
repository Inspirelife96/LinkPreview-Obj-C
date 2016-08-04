//
//  NSURLSession+Sync.m
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 03.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

#import "NSURLSession+Sync.h"

@implementation NSURLSession (Sync)

- (NSData *)synchronousDataTaskWithURL:(NSURL *)url {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSError __block *_err = NULL;
    NSData __block *_data;
    NSURLResponse __block *_resp;
    
    [[self dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        _resp = response;
        _err = error;
        _data = data;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return _data;
}

@end
