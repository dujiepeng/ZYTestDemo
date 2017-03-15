//
//  ConversationListController+GroupRead.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/11.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "ConversationListController+GroupRead.h"
#import <objc/runtime.h>
#import "LocalDataTools.h"

@implementation ConversationListController (GroupRead)

+ (void)load {
    Method oldeditMethod = class_getInstanceMethod([ConversationListController class], @selector(tableView:editActionsForRowAtIndexPath:));
    
    Method neweditMethod = class_getInstanceMethod([ConversationListController class], @selector(GroupReadTableView:editActionsForRowAtIndexPath:));
    
    method_exchangeImplementations(oldeditMethod, neweditMethod);
}

- (NSArray<UITableViewRowAction *> *)GroupReadTableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *rowActions = [self GroupReadTableView:tableView editActionsForRowAtIndexPath:indexPath];
    NSMutableArray *_rowActions = [NSMutableArray arrayWithArray:rowActions];
    
    UITableViewRowAction *removeRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                               title:@"删除"
                                                                             handler:
                                             ^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                 EaseConversationModel *model = [self.dataArray objectAtIndex:indexPath.row];
                                                 [[LocalDataTools tools] removeDataToPlist:model.conversation.conversationId];
                                                 [[EMClient sharedClient].chatManager deleteConversation:model.conversation.conversationId isDeleteMessages:YES completion:nil];
                                                 [self.dataArray removeObjectAtIndex:indexPath.row];
                                                 [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                             }];
    
    removeRowAction.backgroundColor = [UIColor redColor];
    [_rowActions replaceObjectAtIndex:0 withObject:removeRowAction];
    return _rowActions;
}


@end
