//
//  EaseSDKHelper+GoneAfterRead.m
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 2017/3/14.
//  Copyright © 2017年 EaseMob. All rights reserved.
//

#import "EaseSDKHelper+GoneAfterRead.h"
#import <objc/runtime.h>
#import "ChatDemoHelper+GoneAfterRead.h"

@implementation EaseSDKHelper (GoneAfterRead)

+ (void)load
{
    Method sendText = class_getClassMethod([self class], @selector(sendTextMessage:to:messageType:messageExt:));
    Method FSendText = class_getClassMethod([self class], @selector(FSendTextMessage:to:messageType:messageExt:));
    method_exchangeImplementations(sendText, FSendText);
    
    Method sendImage = class_getClassMethod([self class], @selector(sendImageMessageWithImageData:to:messageType:messageExt:));
    Method FSendImage = class_getClassMethod([self class], @selector(FSendImageMessageWithImageData:to:messageType:messageExt:));
    method_exchangeImplementations(sendImage, FSendImage);
    
    Method sendLocation = class_getClassMethod([self class], @selector(sendLocationMessageWithLatitude:longitude:address:to:messageType:messageExt:));
    Method FSendLocation = class_getClassMethod([self class], @selector(FSendLocationMessageWithLatitude:longitude:address:to:messageType:messageExt:));
    method_exchangeImplementations(sendLocation, FSendLocation);
    
    Method sendVoice = class_getClassMethod([self class], @selector(sendVoiceMessageWithLocalPath:duration:to:messageType:messageExt:));
    Method FSendVoice = class_getClassMethod([self class], @selector(FSendVoiceMessageWithLocalPath:duration:to:messageType:messageExt:));
    method_exchangeImplementations(sendVoice, FSendVoice);
    
    Method sendVideo = class_getClassMethod([self class], @selector(sendVideoMessageWithURL:to:messageType:messageExt:));
    Method FSendVideo = class_getClassMethod([self class], @selector(FSendVideoMessageWithURL:to:messageType:messageExt:));
    method_exchangeImplementations(sendVideo, FSendVideo);
    
}

+ (EMMessage *)FSendTextMessage:(NSString *)text to:(NSString *)to messageType:(EMChatType)messageType messageExt:(NSDictionary *)messageExt
{
    EMMessage *msg = [self FSendTextMessage:text to:to messageType:messageType messageExt:messageExt];
    if ([[ChatDemoHelper shareHelper] isGoneAfterReadMode]) {
        
      msg.ext = [ChatDemoHelper structureGoneAfterReadMsgExt:msg.ext];
    }
    return msg;
}

+ (EMMessage *)FSendImageMessageWithImageData:(NSData *)imageData to:(NSString *)to messageType:(EMChatType)messageType messageExt:(NSDictionary *)messageExt
{
    EMMessage *msg = [self FSendImageMessageWithImageData:imageData to:to messageType:messageType messageExt:messageExt];
    if ([[ChatDemoHelper shareHelper] isGoneAfterReadMode]) {
        
        msg.ext = [ChatDemoHelper structureGoneAfterReadMsgExt:msg.ext];
    }
    return msg;
}

+ (EMMessage *)FSendLocationMessageWithLatitude:(double)latitude longitude:(double)longitude address:(NSString *)address to:(NSString *)to messageType:(EMChatType)messageType messageExt:(NSDictionary *)messageExt
{
    EMMessage *msg = [self FSendLocationMessageWithLatitude:latitude longitude:longitude address:address to:to messageType:messageType messageExt:messageExt];
    if ([[ChatDemoHelper shareHelper] isGoneAfterReadMode]) {
        
        msg.ext = [ChatDemoHelper structureGoneAfterReadMsgExt:msg.ext];
    }
    return msg;
}

+ (EMMessage *)FSendVoiceMessageWithLocalPath:(NSString *)localPath duration:(NSInteger)duration to:(NSString *)to messageType:(EMChatType)messageType messageExt:(NSDictionary *)messageExt
{
    EMMessage *msg = [self FSendVoiceMessageWithLocalPath:localPath duration:duration to:to messageType:messageType messageExt:messageExt];
    if ([[ChatDemoHelper shareHelper] isGoneAfterReadMode]) {
        
        msg.ext = [ChatDemoHelper structureGoneAfterReadMsgExt:msg.ext];
    }
    return msg;
}

+ (EMMessage *)FSendVideoMessageWithURL:(NSURL *)url to:(NSString *)to messageType:(EMChatType)messageType messageExt:(NSDictionary *)messageExt
{
    EMMessage *msg = [self FSendVideoMessageWithURL:url to:to messageType:messageType messageExt:messageExt];
    if ([[ChatDemoHelper shareHelper] isGoneAfterReadMode]) {
        
        msg.ext = [ChatDemoHelper structureGoneAfterReadMsgExt:msg.ext];
    }
    return msg;
}



@end
