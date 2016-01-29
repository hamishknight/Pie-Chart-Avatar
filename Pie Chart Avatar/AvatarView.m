//
//  AvatarView.m
//  Pie Chart Avatar
//
//  Created by Hamish Knight on 29/01/2016.
//  Copyright © 2016 Redonkulous Apps. All rights reserved.
//

#import "AvatarView.h"

@implementation AvatarView {
    CALayer* avatarImageLayer; // the avatar image layer
    NSMutableArray* borderLayers; // the array containing the portion border layers
    UIBezierPath* circlePath; // the circle path used for the portion border layers
    CGFloat radius; // the radius of the view
}

-(instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        radius = frame.size.width*0.5;
        circlePath = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius, radius} radius:radius*0.5 startAngle:-M_PI*0.5 endAngle:M_PI*1.5 clockwise:YES];
        
        avatarImageLayer = [CALayer layer];
        avatarImageLayer.frame = frame;
        avatarImageLayer.contentsScale = [UIScreen mainScreen].nativeScale; // scales the layer to the screen scale
        [self.layer addSublayer:avatarImageLayer];
        
    }
    return self;
}

-(void) updateBorder {
    
    if (!borderLayers) borderLayers = [NSMutableArray array];
    
    while (borderLayers.count > _borderValues.count) { // remove layers if the number of border layers got reduced
        [(CAShapeLayer*)[borderLayers lastObject] removeFromSuperlayer];
        [borderLayers removeLastObject];
    }
    
    while (borderLayers.count < _borderValues.count) { // add layers if the number of border layers got increased
        CAShapeLayer* borderLayer = [CAShapeLayer layer];
        borderLayer.path = circlePath.CGPath;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer insertSublayer:borderLayer atIndex:0];
        [borderLayers addObject:borderLayer];
    }
    
    NSUInteger i = 0;
    CGFloat cumulativeValue = 0;
    for (CAShapeLayer* s in borderLayers) {
        
        s.strokeColor = ((UIColor*)_borderColors[i]).CGColor;
        s.lineWidth = radius;
        
        s.strokeStart = cumulativeValue;
        cumulativeValue += [_borderValues[i] floatValue];
        s.strokeEnd = cumulativeValue;
        
        i++;
    }

}

-(void) setAvatarImage:(UIImage *)avatarImage {
    _avatarImage = avatarImage;
    avatarImageLayer.contents = (id)avatarImage.CGImage; // update contents if image changed
}

-(void) setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    
    CGFloat halfBorderWidth = borderWidth*0.5; // we're gonna use this a fair amount, so might as well pre-calculate
    
    avatarImageLayer.frame = CGRectMake(halfBorderWidth, halfBorderWidth, self.frame.size.width-borderWidth, self.frame.size.height-borderWidth); // update avatar image frame
    
    // update avatar masking
    UIBezierPath* p = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius-halfBorderWidth, radius-halfBorderWidth} radius:radius-borderWidth startAngle:-M_PI*0.5 endAngle:M_PI*1.5 clockwise:YES];
    CAShapeLayer* s = [CAShapeLayer layer];
    s.path = p.CGPath;
    
    avatarImageLayer.mask = s;
    
}

-(void) setBorderColors:(NSArray *)borderColors {
    _borderColors = borderColors;
    [self updateBorder];
}

-(void) setBorderValues:(NSArray *)borderValues {
    _borderValues = borderValues;
    [self updateBorder];
}

@end
