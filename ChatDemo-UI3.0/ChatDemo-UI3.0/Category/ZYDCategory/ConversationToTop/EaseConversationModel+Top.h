//
//  EaseConversationModel+Top.h
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 27/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "EaseConversationModel.h"

@interface EaseConversationModel (Top)
- (double)topTime;
- (BOOL)isTop;
- (void)upToTop:(void(^)())completion;
- (void)upToNormal:(void(^)())completion;

@end
