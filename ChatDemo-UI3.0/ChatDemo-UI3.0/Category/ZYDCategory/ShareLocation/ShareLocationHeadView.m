//
//  ShareLocationHeadView.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 01/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ShareLocationHeadView.h"
#import "UIImageView+EMWebCache.h"

#define IMAGESIZE CGSizeMake(60, 60)
#define ArrowWidth 18

@interface UIImage ()
@end


@implementation UIImage (AnnotationView)

- (UIImage*) annotationImage
{
    static UIView *snapshotView = nil;
    static UIImageView *imageView = nil;
    if ( !snapshotView )
    {
        snapshotView = [UIView new];
        snapshotView.frame = CGRectMake(0, 0, IMAGESIZE.width, IMAGESIZE.height);
        imageView = [UIImageView new];
        [snapshotView addSubview:imageView];
        imageView.clipsToBounds = YES;
        imageView.frame = snapshotView.bounds;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        CGFloat arrowWidth = ArrowWidth;
        CGMutablePathRef path = CGPathCreateMutable();
        CGRect rectangle = CGRectInset(CGRectMake(0, 0, CGRectGetWidth(imageView.bounds), CGRectGetWidth(imageView.bounds)), 9,9);
        CGPoint p[3] = {
            {CGRectGetMidX(imageView.bounds) - arrowWidth / 2, CGRectGetWidth(imageView.bounds) - 20},
            {CGRectGetMidX(imageView.bounds) + arrowWidth / 2, CGRectGetWidth(imageView.bounds) - 20},
            {CGRectGetMidX(imageView.bounds), CGRectGetHeight(imageView.bounds) - 2}
        };
        CGPathAddRoundedRect(path, NULL, rectangle, 10, 10);
        CGPathAddLines(path, NULL, p, 3);
        CGPathAddLines(path, NULL, p, 3);
        CGPathCloseSubpath(path);
        CGPathRelease(path);
    }
    imageView.image = self;
    UIGraphicsBeginImageContextWithOptions(IMAGESIZE, NO, 0);
    [snapshotView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *copied = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return copied;
}

@end

@interface ShareLocationHeadView ()
{
    UIImageView *_headerImage;
    UILabel *_nameLabel;
}
@property (nonatomic, strong) UIBezierPath *framePath;

@end

@implementation ShareLocationHeadView

- (instancetype)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    if ([super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])
    {
        self.frame = CGRectMake(0, 0, IMAGESIZE.width, IMAGESIZE.height);
        self.centerOffset = CGPointMake(0, - (IMAGESIZE.height - 3)/2);
        self.canShowCallout = NO;
        _headerImage = [[UIImageView alloc] initWithFrame:self.bounds];
        _headerImage.image = [UIImage imageNamed:@"chatListCellHead"];
        [self addSubview:_headerImage];
        _headerImage.contentMode = UIViewContentModeScaleAspectFill;
        CAShapeLayer *shapelayer = [CAShapeLayer layer];
        shapelayer.frame = self.bounds;
        shapelayer.path = self.framePath.CGPath;
        _headerImage.layer.mask = shapelayer;
        self.layer.shadowPath = self.framePath.CGPath;
        self.layer.shadowRadius = 1.0f;
        self.layer.shadowOpacity = 1.0f;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.masksToBounds = NO;
        
    }
    return self;
}

//mask路径
- (UIBezierPath *)framePath
{
    if ( !_framePath )
    {
        CGFloat arrowWidth = ArrowWidth;
        CGMutablePathRef path = CGPathCreateMutable();
        CGRect rectangle = CGRectInset(CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds)), 9,9);
        CGPoint p[3] = {
            {CGRectGetMidX(self.bounds) - arrowWidth / 2, CGRectGetWidth(self.bounds) - 20},
            {CGRectGetMidX(self.bounds) + arrowWidth / 2, CGRectGetWidth(self.bounds) - 20},
            {CGRectGetMidX(self.bounds), CGRectGetHeight(self.bounds) - 2}
        };
        CGPathAddRoundedRect(path, NULL, rectangle, 10, 10);
        CGPathAddLines(path, NULL, p, 3);
        CGPathCloseSubpath(path);
        _framePath = [UIBezierPath bezierPathWithCGPath:path];
        CGPathRelease(path);
    }
    return _framePath;
}

- (void)loadAnnotationImageWithURL:(NSString*)url imageView:(UIImageView *)aImageView
{
    //将合成后的图片缓存起来
    NSString *annoImageURL = url;
    NSString *annoImageCacheURL = [annoImageURL stringByAppendingString:@"cache"];
    UIImage* cacheImage = [[EMSDImageCache sharedImageCache] imageFromDiskCacheForKey:annoImageCacheURL];
    if(cacheImage)
    {
        aImageView.image = cacheImage;
    }
    else
    {
        [aImageView sd_setImageWithURL:[NSURL URLWithString:annoImageURL] placeholderImage:aImageView.image
                            completed:^(UIImage *image,NSError *error,EMSDImageCacheType cacheType,NSURL *imageURL){
                                if(!error)
                                {
                                    UIImage *annoImage = [image annotationImage];
                                    aImageView.image = annoImage;
                                    [[EMSDImageCache sharedImageCache] storeImage:annoImage forKey:annoImageCacheURL];
                                }
                            }];
    }
}


- (void)setShowName:(NSString *)aName {
    // TODO 画 name label
}

- (void) setHeaderPath:(NSString *)aPath{
    [self loadAnnotationImageWithURL:aPath imageView:_headerImage];
}

@end



