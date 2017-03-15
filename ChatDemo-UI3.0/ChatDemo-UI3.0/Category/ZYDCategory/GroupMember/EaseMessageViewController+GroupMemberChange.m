//
//  EaseMessageViewController+GroupMemberChange.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/15.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EaseMessageViewController+GroupMemberChange.h"
#import <objc/runtime.h>
#import "DefineKey.h"

@implementation EaseMessageViewController (GroupMemberChange)

+ (void)load {
    Method oldMethod = class_getInstanceMethod([EaseMessageViewController class],
                                               @selector(tableView:cellForRowAtIndexPath:));
    Method newMethod = class_getInstanceMethod([EaseMessageViewController class],
                                               @selector(GMCTableView:cellForRowAtIndexPath:));
    method_exchangeImplementations(oldMethod, newMethod);
    
    Method oldHeightMethod = class_getInstanceMethod([EaseMessageViewController class],
                                                     @selector(tableView:heightForRowAtIndexPath:));
    Method newHeightMethod = class_getInstanceMethod([EaseMessageViewController class],
                                                     @selector(GMCTableView:heightForRowAtIndexPath:));
    method_exchangeImplementations(oldHeightMethod, newHeightMethod);
    
    Method oldLPMethod = class_getInstanceMethod([EaseMessageViewController class],
                                                 @selector(handleLongPress:));
    Method newLPMethod = class_getInstanceMethod([EaseMessageViewController class],
                                                 @selector(GMCHandleLongPress:));
    method_exchangeImplementations(oldLPMethod, newLPMethod);
}

- (UITableViewCell *)GMCTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = self.dataArray[indexPath.row];
    if ([obj conformsToProtocol:@protocol(IMessageModel)]) {
        EaseMessageModel *model = (EaseMessageModel *)obj;
        if (model.message.ext[GROUP_MEMBER_CHANGE_INSERT]) {
            NSString *TimeCellIdentifier = [EaseMessageTimeCell cellIdentifier];
            EaseMessageTimeCell *timeCell = (EaseMessageTimeCell *)[tableView dequeueReusableCellWithIdentifier:TimeCellIdentifier];
            
            if (timeCell == nil) {
                timeCell = [[EaseMessageTimeCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:TimeCellIdentifier];
                timeCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            EMTextMessageBody *body = (EMTextMessageBody *)model.message.body;
            timeCell.title = body.text;
            return timeCell;
        }
    }
    return [self GMCTableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)GMCTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = self.dataArray[indexPath.row];
    if ([object conformsToProtocol:@protocol(IMessageModel)]) {
        EaseMessageModel *model = (EaseMessageModel *)object;
        if (model.message.ext[GROUP_MEMBER_CHANGE_INSERT]) {
            return self.timeCellHeight;
        }
    }
    return [self GMCTableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)GMCHandleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan && [self.dataArray count] > 0)
    {
        CGPoint location = [recognizer locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
        id obj = self.dataArray[indexPath.row];
        if ([obj conformsToProtocol:@protocol(IMessageModel)]) {
            EaseMessageModel *model = (EaseMessageModel *)obj;
            if (model.message.ext[GROUP_MEMBER_CHANGE_INSERT]) {
                return;
            }
        }
        [self performSelector:@selector(GMCHandleLongPress:) withObject:recognizer];
    }
}

@end
