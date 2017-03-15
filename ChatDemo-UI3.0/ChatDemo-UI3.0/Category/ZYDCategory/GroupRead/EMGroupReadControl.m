//
//  EMGroupReadControl.m
//  ChatDemo-UI3.0
//
//  Created by WYZ on 2017/3/10.
//  Copyright © 2017年 WYZ. All rights reserved.
//

#import "EMGroupReadControl.h"
#import "DefineKey.h"

@interface EMGroupReadControl()

@property (strong, nonatomic) IBOutlet UILabel *countLabel;

@end

@implementation EMGroupReadControl

- (void)awakeFromNib {
    [super awakeFromNib];
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
}



- (void)setReaders:(NSArray *)readers {
    _readers = [readers copy];
    NSString *content = [NSString stringWithFormat:@"%lu人已读",(unsigned long)_readers.count];
    _countLabel.text = content;
}


- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateEnded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ENTRY_GROUPMSG_READERLIST object:_readers];
    }
}

@end
