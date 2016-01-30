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
    UIBezierPath* borderLayerPath; // the path used to stroke the border layers
    CGFloat radius; // the radius of the view
}

-(instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        radius = frame.size.width*0.5;
        
        borderLayers = [NSMutableArray array];
        
        avatarImageLayer = [CALayer layer];
        avatarImageLayer.frame = frame;
        avatarImageLayer.contentsScale = [UIScreen mainScreen].nativeScale; // scales the layer to the screen scale
        [self.layer addSublayer:avatarImageLayer];
        
    }
    return self;
}

-(void) populateBorderLayers {
    
    while (borderLayers.count > _borderValues.count) { // remove layers if the number of border layers got reduced
        [(CAShapeLayer*)[borderLayers lastObject] removeFromSuperlayer];
        [borderLayers removeLastObject];
    }
    
    NSUInteger colorCount = _borderColors.count;
    NSUInteger borderLayerCount = borderLayers.count;
    
    while (borderLayerCount < _borderValues.count) { // add layers if the number of border layers got increased
        
        CAShapeLayer* borderLayer = [CAShapeLayer layer];
        
        borderLayer.path = borderLayerPath.CGPath;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        borderLayer.lineWidth = _borderWidth;
        borderLayer.strokeColor = (borderLayerCount < colorCount)? ((UIColor*)_borderColors[borderLayerCount]).CGColor : [UIColor clearColor].CGColor;

        
        if (borderLayerCount != 0) {
            CAShapeLayer* previousLayer = borderLayers[borderLayerCount-1];
            borderLayer.strokeStart = previousLayer.strokeEnd;
            borderLayer.strokeEnd = previousLayer.strokeEnd;
        } else {
            borderLayer.strokeStart = 0.0;
            borderLayer.strokeEnd = 0.0;
        }
        
        //[self.layer insertSublayer:borderLayer atIndex:0];
        [self.layer addSublayer:borderLayer];
        [borderLayers addObject:borderLayer];
        
        borderLayerCount++;
    }
}

-(void) updateBorderStrokeValues {
    NSUInteger i = 0;
    CGFloat cumulativeValue = 0;
    for (CAShapeLayer* s in borderLayers) {
        
        s.strokeStart = cumulativeValue;
        cumulativeValue += [_borderValues[i] floatValue];
        s.strokeEnd = cumulativeValue;
        
        i++;
    }
}

-(void) animateToBorderValues:(NSArray *)borderValues duration:(CGFloat)duration {
    
    _borderValues = borderValues; // update border values

    [self populateBorderLayers]; // do a 'soft' layer update, making sure that the correct number of layers are generated pre-animation. Pre-sets stroke positions to a pre-animation state.
    

    CGFloat cumulativeValue = 0;
    for (int i = 0; i < borderValues.count; i++) {
        CGFloat borderValue = [borderValues[i] floatValue];
        CAShapeLayer* s = borderLayers[i];
        
        cumulativeValue += borderValue;

        CABasicAnimation* strokeAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        strokeAnim.duration = duration;
        strokeAnim.fromValue = @(s.strokeEnd);
        strokeAnim.toValue = @(cumulativeValue);
        [s addAnimation:strokeAnim forKey:@"endStrokeAnim"];
        
        if ((i+1) < borderValues.count) {
            
            CAShapeLayer* nextShapeLayer = borderLayers[i+1];
            strokeAnim = [CABasicAnimation animationWithKeyPath:@"strokeStart"]; // yes, I'm recreating the animaton. yes, I should've been able to re-use it. however, for some reason it's not working on the latest iOS beta (probably a bug).
            strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            strokeAnim.duration = duration;
            strokeAnim.fromValue = @(s.strokeEnd);
            strokeAnim.toValue = @(cumulativeValue);
            [nextShapeLayer addAnimation:strokeAnim forKey:@"startStrokeAnim"];
            
        }
    }
    
    // update presentation layer values
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self updateBorderStrokeValues]; // sets stroke positions.
    [CATransaction commit];
    
}

-(void) setAvatarImage:(UIImage *)avatarImage {
    _avatarImage = avatarImage;
    avatarImageLayer.contents = (id)avatarImage.CGImage; // update contents if image changed
}

-(void) setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    
    CGFloat halfBorderWidth = borderWidth*0.5; // we're gonna use this a bunch, so might as well pre-calculate
    
    // set the new border layer path
    borderLayerPath = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius, radius} radius:radius-halfBorderWidth startAngle:-M_PI*0.5 endAngle:M_PI*1.5 clockwise:YES];
    
    for (CAShapeLayer* s in borderLayers) { // apply the new border layer path
        s.path = borderLayerPath.CGPath;
        s.lineWidth = borderWidth;
    }
    
    // update avatar masking
    CAShapeLayer* s = [CAShapeLayer layer];
    s.path = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius-halfBorderWidth, radius-halfBorderWidth} radius:radius-borderWidth startAngle:-M_PI*0.5 endAngle:M_PI*1.5 clockwise:YES].CGPath;
    
    avatarImageLayer.frame = CGRectMake(halfBorderWidth, halfBorderWidth, self.frame.size.width-borderWidth, self.frame.size.height-borderWidth); // update avatar image frame
    avatarImageLayer.mask = s;
    
}

-(void) setBorderColors:(NSArray *)borderColors {
    _borderColors = borderColors;
    
    NSUInteger i = 0;
    for (CAShapeLayer* s in borderLayers) {
        s.strokeColor = ((UIColor*)borderColors[i]).CGColor;
        i++;
    }
}

-(void) setBorderValues:(NSArray *)borderValues {
    _borderValues = borderValues;
    [self populateBorderLayers];
    [self updateBorderStrokeValues];
}

@end
