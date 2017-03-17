//
//  EaseMessageReadManager+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseMessageReadManager+GoneAfterRead.h"
#import <objc/runtime.h>

@interface EaseMessageReadManager()


@end

@implementation EaseMessageReadManager (GoneAfterRead)

- (id<IMessageModel>)imageModel
{
    return objc_getAssociatedObject(self, @selector(imageModel));
}

- (void)setImageModel:(id<IMessageModel>)imageModel
{
    objc_setAssociatedObject(self, @selector(imageModel), imageModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<EaseMessageReadManagerDelegate>)readDelegate
{
    return objc_getAssociatedObject(self, @selector(readDelegate));
}
- (void)setReadDelegate:(id<EaseMessageReadManagerDelegate>)readDelegate
{
    return objc_setAssociatedObject(self, @selector(readDelegate), readDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser
{
    if (!self.imageModel.isSender && self.readDelegate && [self.readDelegate respondsToSelector:@selector(readMessageFinished:)]) {
        
        [self.readDelegate readMessageFinished:self.imageModel];
    }
    [photoBrowser dismissViewControllerAnimated:YES completion:nil];
    
}
@end
