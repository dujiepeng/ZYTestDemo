//
//  ShareLocationAnnotation.h
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 01/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ISSTOP @"isStop"

@interface ShareLocationAnnotation : NSObject <MKAnnotation>
@property (nonatomic,assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatarPath;

-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

@end
