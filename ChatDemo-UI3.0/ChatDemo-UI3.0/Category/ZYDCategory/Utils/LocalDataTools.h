//
//  LocalDataTools.h
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/9.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalDataTools : NSObject

+ (LocalDataTools *)tools;

@property (nonatomic, strong) NSMutableDictionary *groupReadItems;

- (void)clearCurrentGroupReadItems;

/*
 * 获取plist文件数据
 */
- (void)getLocalGroupReadItemsFromPlist:(NSString *)conversationId;


/*
 * plist文件添加数据
 */
- (void)addDataToPlist:(NSString*)groupId msgIds:(NSArray *)msgIds readerName:(NSString *)readerName;


/*
 * plist文件删除数据
 */
- (void)removeDataToPlist:(NSString*)groupId;

- (void)removeDataToPlist:(NSString*)groupId messageId:(NSString *)messageId;

@end
