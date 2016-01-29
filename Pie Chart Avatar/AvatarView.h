//
//  AvatarView.h
//  Pie Chart Avatar
//
//  Created by Hamish Knight on 29/01/2016.
//  Copyright © 2016 Redonkulous Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Provides a simple interface for creating an avatar icon, with a pie-chart style border.
@interface AvatarView : UIView

/// The avatar image, to be displayed in the center.
@property (nonatomic) UIImage* avatarImage;

/// An array of float values to define the values of each portion of the border.
@property (nonatomic) NSArray* borderValues;

/// An array of UIColors to define the colors of the border portions.
@property (nonatomic) NSArray* borderColors;

/// The width of the outer border.
@property (nonatomic) CGFloat borderWidth;

-(void) animateToBorderValues:(NSArray*)borderValues duration:(CGFloat)duration;

@end
