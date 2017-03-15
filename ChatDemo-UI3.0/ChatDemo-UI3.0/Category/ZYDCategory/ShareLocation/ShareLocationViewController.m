//
//  ShareLocationViewController.m
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 28/02/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import "ShareLocationViewController.h"
#import "ShareLocationHeadView.h"
#import "ShareLocationAnnotation.h"
#import "ChatViewController+ShareLocation.h"
#import <MapKit/MapKit.h>

@interface ShareLocationViewController () <MKMapViewDelegate>
{
    NSString *_currentUsername;
    EMConversationType _conversationType;
    CLLocationManager *_locationManager;
    double _latitude;
    double _longitude;
    BOOL _firstLocation;
}
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSObject *lock;
@property (nonatomic, strong) NSMutableArray *voices;
@end

@implementation ShareLocationViewController

- (instancetype)initWithShareLocationToChatter:(NSString *)conversationChatter conversationType:(EMConversationType)conversationType {
    if (self = [super init]) {
        _currentUsername = conversationChatter;
        _conversationType = conversationType;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _lock = [[NSObject alloc] init];
    [self.view addSubview:self.mapView];
    [self setupViews];
    [self startLocation];
    [self registerNotifications];
    [self sentStartLocationMessage];
}

- (void)sentStartLocationMessage {
    UINavigationController *navVC = (UINavigationController *)self.parentViewController;
    for (id vc in navVC.viewControllers) {
        if ([vc isKindOfClass:[ChatViewController class]]) {
            ChatViewController *chatVC = vc;
            [chatVC sendTextMessage:@"发起位置共享" withExt:@{@"shareLocation":@YES}];
            break;
        }
    }
}

- (void)stopSharing {
    UINavigationController *navVC = (UINavigationController *)self.parentViewController;
    for (id vc in navVC.viewControllers) {
        if ([vc isKindOfClass:[ChatViewController class]]) {
            ChatViewController *chatVC = vc;
            [chatVC sendTextMessage:@"停止了位置共享" withExt:@{@"shareLocation":@NO}];
            break;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:@"shareLocation"];
        NSString *from = [[EMClient sharedClient] currentUsername];
        NSDictionary *ext = @{@"isStop":@YES};
        EMMessage *message = [[EMMessage alloc] initWithConversationID:self->_currentUsername
                                                                  from:from
                                                                    to:self->_currentUsername
                                                                  body:body
                                                                   ext:ext];
        message.chatType = [self _messageTypeFromConversationType];
        [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:nil];
    });
}

- (void)setupViews {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    view.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
    [self.view addSubview:view];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(30, 30, 80, 30);
    [btn setBackgroundColor:[UIColor blueColor]];
    [btn setTitle:@"停止" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveLocations:)
                                                 name:@"ShareLocations"
                                               object:nil];
}

- (void)didReceiveLocations:(NSNotification *)noti {
    @synchronized (_lock) {
        if ([noti.object isKindOfClass:[NSSet class]]) {
            NSMutableArray *needRemoves = [[NSMutableArray alloc] init];
            NSMutableArray *needAdds = [[NSMutableArray alloc] init];
            NSArray *infoDicts = [noti.object allObjects];
            for (NSDictionary *dic in infoDicts) {
                NSString *username = dic[@"username"];
                double lan = [dic[@"lan"] doubleValue];
                double lon = [dic[@"lon"] doubleValue];
                BOOL isStop = [dic[@"isStop"] boolValue];
                if (username && [username isKindOfClass:[NSString class]]) {
                    for (NSObject *obj in self.mapView.annotations) {
                        if ([obj isKindOfClass:[ShareLocationAnnotation class]]) {
                            ShareLocationAnnotation *inAn = (ShareLocationAnnotation *)obj;
                            [needRemoves addObject:inAn];
                        }
                    }
                    
                    if (isStop) {
                        continue;
                    }
                    ShareLocationAnnotation *an = [[ShareLocationAnnotation alloc] init];
                    an.username = username;
                    [an setCoordinate:CLLocationCoordinate2DMake(lan, lon)];
                    [needAdds addObject:an];
                }
            }
            
            if (needRemoves.count > 0) {
                [self.mapView removeAnnotations:needRemoves];
            }
            
            if (needAdds.count > 0) {
                [self.mapView addAnnotations:needAdds];
            }
        }
    }
}

- (MKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        _mapView.frame = self.view.bounds;
        _mapView.delegate = self;
        _mapView.showsUserLocation = YES;
    }
    
    return _mapView;
}

- (void)backAction {
    
    [self stopSharing];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
didChangeDragState:(MKAnnotationViewDragState)newState
  fromOldState:(MKAnnotationViewDragState)oldState{
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if(!_firstLocation){
        _firstLocation = YES;
        CLLocationCoordinate2D loc = [userLocation coordinate];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 400, 400);
        [self.mapView setRegion:region animated:NO];
    }
    _latitude = userLocation.coordinate.latitude;
    _longitude = userLocation.coordinate.longitude;
    [self sendShareLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *pick = @"pickey";
    if ([annotation isKindOfClass:[ShareLocationAnnotation class]]) {
        pick = ((ShareLocationAnnotation *)annotation).username;
    }
    ShareLocationHeadView *pinView = (ShareLocationHeadView *) [mapView dequeueReusableAnnotationViewWithIdentifier:pick];
    if (!pinView) {
        pinView = [[ShareLocationHeadView alloc] initWithAnnotation:annotation
                                                    reuseIdentifier:pick];
    }
    
    if ([annotation isKindOfClass:[ShareLocationAnnotation class]]) {
        ShareLocationAnnotation *slAnnotation = (ShareLocationAnnotation *)annotation;
        // TODO 设置头像
        [pinView setShowName:slAnnotation.nickname ? slAnnotation.nickname : slAnnotation.username];
        [pinView setHeaderPath:slAnnotation.avatarPath];
        [pinView setAnnotation:slAnnotation];
    }else {
        [pinView setShowName:@"test"];
        [pinView setHeaderPath:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1488375108725&di=1bfd8069ebc59d2c4d1c038a146dab22&imgtype=0&src=http%3A%2F%2Fh.hiphotos.baidu.com%2Fzhidao%2Fpic%2Fitem%2F0eb30f2442a7d9334f268ca9a84bd11372f00159.jpg"];
    }
    
    return pinView;
}

- (void)startLocation
{
    if([CLLocationManager locationServicesEnabled]){
        _locationManager = [[CLLocationManager alloc] init];
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
}

- (void)sendShareLocation {
    EMCmdMessageBody *body = [[EMCmdMessageBody alloc] initWithAction:@"shareLocation"];
    NSString *from = [[EMClient sharedClient] currentUsername];
    NSDictionary *ext = @{LATITUDE:[NSNumber numberWithDouble:_latitude],LONGITUDE:[NSNumber numberWithDouble:_longitude]};
    EMMessage *message = [[EMMessage alloc] initWithConversationID:_currentUsername
                                                              from:from
                                                                to:_currentUsername
                                                              body:body
                                                               ext:ext];
    message.chatType = [self _messageTypeFromConversationType];
    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:nil];
}

- (EMChatType)_messageTypeFromConversationType
{
    EMChatType type = EMChatTypeChat;
    switch (_conversationType) {
        case EMConversationTypeChat:
            type = EMChatTypeChat;
            break;
        case EMConversationTypeGroupChat:
            type = EMChatTypeGroupChat;
            break;
        case EMConversationTypeChatRoom:
            type = EMChatTypeChatRoom;
            break;
        default:
            break;
    }
    return type;
}

@end
