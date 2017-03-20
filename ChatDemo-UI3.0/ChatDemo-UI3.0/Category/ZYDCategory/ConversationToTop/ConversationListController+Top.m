//
//  ConversationListController+Top.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ConversationListController+Top.h"
#import "EaseConversationModel+Top.h"


@implementation ConversationListController (Top)


- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *removeRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                               title:@"删除"
                                                                             handler:
                                             ^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                 EaseConversationModel *model = [self.dataArray objectAtIndex:indexPath.row];
                                                 [[EMClient sharedClient].chatManager deleteConversation:model.conversation.conversationId isDeleteMessages:YES completion:nil];
                                                 [self.dataArray removeObjectAtIndex:indexPath.row];
                                                 [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                                             }];
    
    removeRowAction.backgroundColor = [UIColor redColor];
    
    EaseConversationModel *model = [self.dataArray objectAtIndex:indexPath.row];
    UITableViewRowAction *toTopAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                           title:model.isTop?@"取消置顶":@"置顶"
                                                                         handler:
                                         ^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                             EaseConversationModel *model = [self.dataArray objectAtIndex:indexPath.row];
                                             if (model.isTop) {
                                                 [model upToNormal:^{
                                                     [self tableViewDidTriggerHeaderRefresh];
                                                 }];
                                             }else {
                                                 [model upToTop:^{
                                                     [self tableViewDidTriggerHeaderRefresh];
                                                 }];
                                             }
                                             
                                         }];
    toTopAction.backgroundColor = [UIColor lightGrayColor];
    NSArray *arr = @[removeRowAction,toTopAction];
    return arr;
}

- (void)refreshAndSortView
{
    if ([self.dataArray count] > 1) {
        if ([[self.dataArray objectAtIndex:0] isKindOfClass:[EaseConversationModel class]]) {
            NSMutableArray *topAry = [[NSMutableArray alloc] init];
            NSMutableArray *unTopAry = [[NSMutableArray alloc] init];
            for (EaseConversationModel *model in self.dataArray) {
                if (model.isTop) {
                    [topAry addObject:model];
                }else {
                    [unTopAry addObject:model];
                }
            }
            
            NSArray* topSorted = [topAry sortedArrayUsingComparator:
                                  ^(EaseConversationModel *obj1, EaseConversationModel* obj2){
                                      EMMessage *message1 = [obj1.conversation latestMessage];
                                      EMMessage *message2 = [obj2.conversation latestMessage];
                                      if(message1.timestamp > message2.timestamp) {
                                          return(NSComparisonResult)NSOrderedAscending;
                                      }else {
                                          return(NSComparisonResult)NSOrderedDescending;
                                      }
                                  }];

            NSArray* unTopSorted = [unTopAry sortedArrayUsingComparator:
                                    ^(EaseConversationModel *obj1, EaseConversationModel* obj2){
                                        EMMessage *message1 = [obj1.conversation latestMessage];
                                        EMMessage *message2 = [obj2.conversation latestMessage];
                                        if(message1.timestamp > message2.timestamp) {
                                            return(NSComparisonResult)NSOrderedAscending;
                                        }else {
                                            return(NSComparisonResult)NSOrderedDescending;
                                        }
                                    }];
            
            [self.dataArray removeAllObjects];
            [self.dataArray addObjectsFromArray:topSorted];
            [self.dataArray addObjectsFromArray:unTopSorted];
        }
    }
    [self.tableView reloadData];
}

-(void)tableViewDidTriggerHeaderRefresh {
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    NSMutableArray *topAry = [[NSMutableArray alloc] init];
    NSMutableArray *unTopAry = [[NSMutableArray alloc] init];
    for (EMConversation *converstion in conversations) {
        if([converstion.conversationId isEqualToString:@"admin"]) {
            continue;
        }
        EaseConversationModel *model = nil;
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(conversationListViewController:modelForConversation:)]) {
            model = [self.dataSource conversationListViewController:self
                                               modelForConversation:converstion];
        }
        else{
            model = [[EaseConversationModel alloc] initWithConversation:converstion];
        }
        
        if (model) {
            if (!model.isTop) {
                [unTopAry addObject:model];
            } else {
                [topAry addObject:model];
            }
        }
    }
    
    NSArray *topSorted = [topAry sortedArrayUsingComparator:
                          ^(EaseConversationModel *obj1, EaseConversationModel* obj2){
                              EMMessage *message1 = [obj1.conversation latestMessage];
                              EMMessage *message2 = [obj2.conversation latestMessage];
                              if(message1.timestamp > message2.timestamp) {
                                  return(NSComparisonResult)NSOrderedAscending;
                              }else {
                                  return(NSComparisonResult)NSOrderedDescending;
                              }
                          }];
    
    NSArray *unTopSorted = [unTopAry sortedArrayUsingComparator:
                            ^(EaseConversationModel *obj1, EaseConversationModel* obj2){
                                EMMessage *message1 = [obj1.conversation latestMessage];
                                EMMessage *message2 = [obj2.conversation latestMessage];
                                if(message1.timestamp > message2.timestamp) {
                                    return(NSComparisonResult)NSOrderedAscending;
                                }else {
                                    return(NSComparisonResult)NSOrderedDescending;
                                }
                            }];
    
    [self.dataArray removeAllObjects];
    [self.dataArray addObjectsFromArray:topSorted];
    [self.dataArray addObjectsFromArray:unTopSorted];
    [self.tableView reloadData];
    [self tableViewDidFinishTriggerHeader:YES reload:NO];
}
@end
