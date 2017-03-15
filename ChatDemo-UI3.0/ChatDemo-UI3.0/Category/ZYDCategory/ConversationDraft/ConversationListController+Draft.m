//
//  ConversationListController+Draft.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 02/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ConversationListController+Draft.h"
#import "EMConversation+Draft.h"
#import "EaseConversationModel+Top.h"

@implementation ConversationListController (Draft)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EaseConversationCell *cell = (EaseConversationCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    EaseConversationModel *model = cell.model;
    if (model.conversation.draft && model.conversation.draft.length > 0) {
        cell.detailLabel.text = [NSString stringWithFormat:@"[草稿]%@",model.conversation.draft];
    }
    
    return cell;
}
@end
