//
//  NSURL+AVURLAdd.h
//  AVURLPlayer
//
//  Created by karlcool on 2018/1/31.
//  Copyright © 2018年 karlcool. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (AVURLAdd)
- (NSURL *)au_customSchemeURL;
- (NSURL *)au_originalSchemeURL;
@end
