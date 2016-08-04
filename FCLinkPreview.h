//
//  FCLinkPreview.h
//  FCLinkPreview
//
//  Created by Smolski, Aliaksei on 04.08.16.
//  Copyright © 2016 Smolski, Aliaksei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCLinkPreview : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSMutableDictionary *result;

- (void)previewWithText:(NSString *)text  onSuccess:(void (^)(NSMutableDictionary *result))success
                onError:(void (^)(NSNumber *errorCode, NSString *desc))failure;
@end
