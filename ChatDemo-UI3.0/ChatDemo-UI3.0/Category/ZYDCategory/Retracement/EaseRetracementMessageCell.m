//
//  EaseRetracementMessageCell.m
//  ChatDemo-UI3.0
//
//  Created by 蒋月婷 on 17/3/14.
//  Copyright © 2017年 蒋月婷. All rights reserved.
//

#import "EaseRetracementMessageCell.h"
#define SCRERNWIDTH      [[UIScreen mainScreen] bounds].size.width

CGFloat const RetracementMessage = 5;

@interface EaseRetracementMessageCell()

@property (strong, nonatomic) UILabel *titleLabel;

@end
@implementation EaseRetracementMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (void)initialize
{

}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self _setupSubview];
    }
    
    return self;
}

#pragma mark - setup subviews

- (void)_setupSubview
{
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.backgroundColor =[UIColor colorWithRed:0.96f green:0.96f blue:0.96f alpha:1.00f];
    _titleLabel.layer.cornerRadius = RetracementMessage;
    _titleLabel.layer.borderWidth = 0.1;
    _titleLabel.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _titleLabel.textColor = [UIColor lightGrayColor];
    _titleLabel.center = self.contentView.center;
    
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:_titleLabel];
    
}

#pragma mark - Setup Constraints

- (void)_setupTitleLabelConstraints
{
    CGSize contentSize = [self sizeWithText:_titleLabel.text font:[UIFont systemFontOfSize:12] maxSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    CGFloat contentW =contentSize.width;
    CGFloat Width = (SCRERNWIDTH - contentW)/2;
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:RetracementMessage]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-RetracementMessage]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-Width]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:Width]];
}


#pragma mark - setter

- (void)setTitle:(NSString *)title
{
    _title = title;
    _titleLabel.text = _title;
    [self _setupTitleLabelConstraints];
}

- (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font maxSize:(CGSize)maxSize
{
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

#pragma mark - public

+ (NSString *)cellIdentifier
{
    return @"RetracementCell";
}


@end
