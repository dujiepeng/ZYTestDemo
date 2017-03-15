//
//  ShareLocationHeadView.h
//  ChatDemo-UI3.0
//
//  Created by 杜洁鹏 on 01/03/2017.
//  Copyright © 2017 杜洁鹏. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface UIImage (AnnotationView)
@end

@interface ShareLocationHeadView : MKAnnotationView
- (void) setShowName:(NSString *)aName;
- (void) setHeaderPath:(NSString *)aPath;
@end


