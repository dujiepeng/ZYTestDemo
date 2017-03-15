//
//  LocalDataTools.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/9.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "LocalDataTools.h"
#import "DefineKey.h"

@class QueueHandle;
static LocalDataTools *_tools = nil;

@interface LocalDataTools()

@property (nonatomic, strong) NSString *currentGroupId;

@property (nonatomic, strong) NSMutableDictionary *handleDic; //key:groupId value:QueueHandle

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) dispatch_queue_t timerQueue;

@end

/*
 * 数据结构 每个group一个plist
 * 字典
 *    item
 *        key：messageId
 *                  value: 数组
 *                            reader hyphenateId
 *
 */


@interface QueueHandle : NSObject<NSCopying>

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSObject *synchronizedObject;

- (instancetype)initWithQueue:(dispatch_queue_t)queue synchronizedObject:(NSObject *)synchronizedObject;

@end

@implementation QueueHandle

- (instancetype)initWithQueue:(dispatch_queue_t)queue
           synchronizedObject:(NSObject *)synchronizedObject {
    self = [super init];
    if (self) {
        _queue = queue;
        _synchronizedObject = synchronizedObject;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    
    QueueHandle *handle = [[[self class] allocWithZone:zone] init];
    handle.queue = self.queue;
    handle.synchronizedObject = self.synchronizedObject;
    
    return handle;
}

@end


@implementation LocalDataTools

+ (LocalDataTools *)tools {
    static dispatch_once_t once;
    dispatch_once(&once, ^(){
        _tools = [[LocalDataTools alloc] init];
    });
    return _tools;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timerQueue = dispatch_queue_create("timerLoop", DISPATCH_QUEUE_SERIAL);
        _handleDic = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Private

/*
 * plist文件名
 */
- (NSString *)localPlistName {
    NSString *name = nil;
    NSString *_currentUsername = [EMClient sharedClient].currentUsername;
    name = [@"groupReadData_" stringByAppendingFormat:@"%@.plist",_currentUsername];
    return name;
}

/*
 * plist文件夹路径
 */
- (NSString *)localPlistFolderPath:(NSString *)conversationId {
    NSString *path = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/HyphenateSDK/appdata/%@/%@",[EMClient sharedClient].currentUsername, conversationId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        BOOL isCreate = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (isCreate && !error) {
            return path;
        }
        else {
            return nil;
        }
    }
    return path;
}

/*
 * plist文件路径
 */
- (NSString *)localPlistPath:(NSString *)conversationId {
    NSString *folderPath = [self localPlistFolderPath:conversationId];
    if (!folderPath) {
        return nil;
    }
    NSString *path = [folderPath stringByAppendingPathComponent:[_tools localPlistName]];
    return path;
}

- (BOOL)removePlistFile:(NSString *)groupId {
    NSString *path = [self localPlistPath:groupId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        BOOL isRemove = [fileManager removeItemAtPath:path error:&error];
        return isRemove && !error;
    }
    return YES;
}

/*
 * 获取指定群组的队列，以及同步锁对象
 */
- (QueueHandle *)getGrouphandelModel:(NSString *)groupId {
    [self startTimerRunLoop];
    QueueHandle *handle = nil;
    if (_handleDic[groupId]) {
        handle = _handleDic[groupId];
    }
    else {
        const char * idChar = [groupId cStringUsingEncoding:NSUTF8StringEncoding];
        dispatch_queue_t queue = dispatch_queue_create(idChar, DISPATCH_QUEUE_SERIAL);
        NSObject *obj = [[NSObject alloc] init];
        handle = [[QueueHandle alloc] initWithQueue:queue synchronizedObject:obj];
        [_handleDic setObject:handle forKey:groupId];
    }
    return handle;
}

- (BOOL)saveDataToPlist:(NSString*)path groupReadItems:(NSDictionary*)groupReadItems{
    return [groupReadItems writeToFile:path atomically:YES];
    
}

//接收方，启动runloop
- (void)startTimerRunLoop
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(_timerQueue, ^{
        __strong typeof(LocalDataTools) *strongSelf = weakSelf;
        [strongSelf stopRunLoop];
        if (!strongSelf.timer) {
            strongSelf.timer = [NSTimer scheduledTimerWithTimeInterval:CLEAR_QUEUE_TIME target:strongSelf selector:@selector(handleTimerAction:) userInfo:nil repeats:NO];
            NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
            [currentRunLoop addTimer:strongSelf.timer forMode:NSRunLoopCommonModes];
            [currentRunLoop run];
        }
    });
}

//关闭runloop
- (void)stopRunLoop
{
    if (self.timer.isValid)
    {
        [self.timer invalidate];
        self.timer = nil;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
    }
}

//定时处理方法
- (void)handleTimerAction:(NSTimer *)timer
{
    //规定时间内接收方没有收到输入状态通知
    [self stopRunLoop];
    @synchronized (_tools) {
        QueueHandle *currentHandle = nil;
        if (_tools.currentGroupId.length > 0 && _tools.handleDic[_tools.currentGroupId]) {
            currentHandle = [_tools.handleDic[_tools.currentGroupId] copy];
        }
        [_tools.handleDic removeAllObjects];
        if (currentHandle) {
            [_tools.handleDic setObject:currentHandle forKey:_tools.currentGroupId];
        }
    }
}

#pragma mark - Public

/*
 * plist文件添加数据
 */
- (void)addDataToPlist:(NSString*)groupId
                msgIds:(NSArray *)msgIds
            readerName:(NSString *)readerName
{
    if (groupId.length == 0 ||
        msgIds.count == 0 ||
        readerName.length == 0)
    {
        return;
    }
    __weak typeof(self) weakTools = _tools;
    QueueHandle *handle = [self getGrouphandelModel:groupId];
    
    dispatch_async(handle.queue, ^(){
        __strong typeof(LocalDataTools) *strongTools = weakTools;
        
        @synchronized (handle.synchronizedObject) {
            NSString *path = [strongTools localPlistPath:groupId];
            if ([strongTools.currentGroupId isEqualToString:groupId]) {
                if (!strongTools.groupReadItems) {
                    strongTools.groupReadItems = [NSMutableDictionary dictionary];
                }
                for (NSString *msgId in msgIds) {
                    NSMutableArray *readers = [NSMutableArray arrayWithArray:strongTools.groupReadItems[msgId]];
                    if (![readers containsObject:readerName]) {
                        [readers addObject:readerName];
                    }
                    [strongTools.groupReadItems setObject:readers forKey:msgId];
                }
                
                if ([strongTools saveDataToPlist:path groupReadItems:strongTools.groupReadItems]) {
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_GROUPMSG_READCOUNT
                                                                            object:msgIds];
                    });
                }
                else {
                    NSLog(@"保存数据失败: 群组id：%@ 消息id：%@  已读人：%@", groupId,msgIds,readerName);
                }
            }
            else {
                NSMutableDictionary *groupReadItems = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                if (!groupReadItems) {
                    groupReadItems = [NSMutableDictionary dictionary];
                }
                for (NSString *msgId in msgIds) {
                    NSArray *_readers = groupReadItems[msgId];
                    if (!_readers) {
                        [groupReadItems setObject:@[readerName] forKey:msgId];
                    }
                    else {
                        NSMutableArray *readers = [NSMutableArray arrayWithArray:_readers];
                        if (![readers containsObject:readerName]) {
                            [readers addObject:readerName];
                        }
                        [groupReadItems setObject:readers forKey:msgId];
                    }
                }
                if (![strongTools saveDataToPlist:path groupReadItems:groupReadItems]) {
                    NSLog(@"保存数据失败: 群组id：%@ 消息id：%@  已读人：%@", groupId,msgIds,readerName);
                }
                
            }
        }
    });
}

/*
 * plist文件删除数据
 */
- (void)removeDataToPlist:(NSString*)groupId
{
    if (groupId.length == 0)
    {
        return;
    }
    __weak typeof(self) weakTools = _tools;
    QueueHandle *handle = [self getGrouphandelModel:groupId];
    
    dispatch_async(handle.queue, ^(){
        __strong typeof(LocalDataTools) *strongTools = weakTools;
        
        @synchronized (handle.synchronizedObject) {
            [strongTools removePlistFile:groupId];
            if (strongTools.groupReadItems) {
                [strongTools.groupReadItems removeAllObjects];
                strongTools.groupReadItems = nil;
            }
            
            if (strongTools.currentGroupId.length > 0) {
                strongTools.currentGroupId = nil;
            }
        }
    });
}

- (void)removeDataToPlist:(NSString*)groupId
                messageId:(NSString *)messageId
{
    if (groupId.length == 0 ||
        messageId.length == 0)
    {
        return;
    }
    __weak typeof(self) weakTools = _tools;
    QueueHandle *handle = [self getGrouphandelModel:groupId];
    
    dispatch_async(handle.queue, ^(){
        __strong typeof(LocalDataTools) *strongTools = weakTools;
        
        @synchronized (handle.synchronizedObject) {
            NSString *path = [strongTools localPlistPath:groupId];
            if ([strongTools.currentGroupId isEqualToString:groupId]) {
                if (!strongTools.groupReadItems) {
                    strongTools.groupReadItems = [NSMutableDictionary dictionary];
                }
                [strongTools.groupReadItems removeObjectForKey:messageId];
                [strongTools saveDataToPlist:path groupReadItems:strongTools.groupReadItems];
            }
            else {
                NSMutableDictionary *groupReadItems = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                [groupReadItems removeObjectForKey:messageId];
                [strongTools saveDataToPlist:path groupReadItems:groupReadItems];
            }
        }
    });
}

- (void)getLocalGroupReadItemsFromPlist:(NSString *)conversationId {
    if (![EMClient sharedClient].isLoggedIn) {
        return;
    }
    NSString *path = [_tools localPlistPath:conversationId];
    if (path.length == 0) {
        return;
    }
    
    [self clearCurrentGroupReadItems];
    
    _currentGroupId = conversationId;
    NSDictionary *groupReadItems = [[NSDictionary alloc] initWithContentsOfFile:path];
    _tools.groupReadItems = [NSMutableDictionary dictionaryWithDictionary:groupReadItems];
    [self getGrouphandelModel:conversationId];
}

- (void)clearCurrentGroupReadItems {
    @synchronized (_tools) {
        
        if ([_tools.handleDic.allKeys containsObject:_tools.currentGroupId] && _tools.currentGroupId.length > 0) {
            [_tools.handleDic removeObjectForKey:_tools.currentGroupId];
        }
        
        if (_tools.groupReadItems) {
            [_tools.groupReadItems removeAllObjects];
            _tools.groupReadItems = nil;
        }
        
        if (_tools.currentGroupId.length > 0) {
            _currentGroupId = nil;
        }
        
    }
}

@end
