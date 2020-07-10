//
//  NSURL+AVURLAdd.m
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/31.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import "NSURL+AVURLAdd.h"

@implementation NSURL (AVURLAdd)
- (NSURL *)au_customSchemeURL {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = [NSString stringWithFormat:@"vvv%@", self.scheme];
    return [components URL];
}

- (NSURL *)au_originalSchemeURL {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = [self.scheme stringByReplacingOccurrencesOfString:@"vvv" withString:@""];
    return [components URL];
}
@end
