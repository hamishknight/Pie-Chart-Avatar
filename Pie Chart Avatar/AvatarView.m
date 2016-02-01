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
    NSArray* cumulativeBorderValues; // the array containing the cumulative border values
    UIBezierPath* borderLayerPath; // the path used to stroke the border layers
    CGFloat radius; // the radius of the view
}

-(instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        radius = frame.size.width*0.5;
        
        // create border layer array
        borderLayers = [NSMutableArray array];
        
        // create avatar image layer
        avatarImageLayer = [CALayer layer];
        avatarImageLayer.frame = frame;
        avatarImageLayer.contentsScale = [UIScreen mainScreen].nativeScale; // scales the layer to the screen scale
        [self.layer addSublayer:avatarImageLayer];
        
    }
    return self;
}

-(void) populateBorderLayers {
    
    [self calculateCumulativeValues]; // calculate cumulative values of the border values

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
        borderLayer.lineWidth = _borderStrokeWidth;
        borderLayer.strokeColor = (borderLayerCount < colorCount)? ((UIColor*)_borderColors[borderLayerCount]).CGColor : [UIColor clearColor].CGColor;

        if (borderLayerCount != 0) { // set pre-animation border stroke positions.
            
            CAShapeLayer* previousLayer = borderLayers[borderLayerCount-1];
            borderLayer.strokeStart = previousLayer.strokeEnd;
            borderLayer.strokeEnd = previousLayer.strokeEnd;
            
        } else borderLayer.strokeEnd = 0.0; // default value for first layer.
        
        [self.layer insertSublayer:borderLayer atIndex:0]; // not strictly necessary, should work fine with `addSublayer`, but nice to have to ensure the layers don't unexpectedly overlap.
        [borderLayers addObject:borderLayer];
        
        borderLayerCount++;
    }
}

-(void) updateBorderStrokeValues {
    NSUInteger i = 0;
    for (CAShapeLayer* s in borderLayers) {
        s.strokeStart = [cumulativeBorderValues[i] floatValue];
        i++;
        s.strokeEnd = [cumulativeBorderValues[i] floatValue];
    }
}

-(void) animateToStrokeWidth:(CGFloat)borderStrokeWidth duration:(CGFloat)duration {
    
    borderStrokeWidth *= 2.0; // doubles the stroke width, as internally it's double what the user expects.
    
    [self populateBorderLayers]; // do 'soft' layer update
    
    CABasicAnimation* strokeAnim = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
    strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    strokeAnim.duration = duration;
    
    for (CAShapeLayer* s in borderLayers) {
        strokeAnim.fromValue = @(_borderStrokeWidth);
        strokeAnim.toValue = @(borderStrokeWidth);
        [s addAnimation:strokeAnim forKey:@"strokeAnim"];
    }
    
    // update presentation layer values
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.borderStrokeWidth = borderStrokeWidth;
    [CATransaction commit];
}

-(void) animateToBorderValues:(NSArray *)borderValues duration:(CGFloat)duration {
    
    _borderValues = borderValues; // update border values
    
    [self populateBorderLayers]; // do a 'soft' layer update, making sure that the correct number of layers are generated pre-animation. Pre-sets stroke positions to a pre-animation state.
    
    // define stroke animation
    CABasicAnimation* strokeAnim = [CABasicAnimation animation];
    strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    strokeAnim.duration = duration;
    
    for (int i = 0; i < borderLayers.count; i++) {
        
        CAShapeLayer* s = borderLayers[i];

        if (i != 0) [s addAnimation:strokeAnim forKey:@"startStrokeAnim"];
        
        // define stroke end animation
        strokeAnim.keyPath = @"strokeEnd";
        strokeAnim.fromValue = @(s.strokeEnd);
        strokeAnim.toValue = @([cumulativeBorderValues[i+1] floatValue]);
        [s addAnimation:strokeAnim forKey:@"endStrokeAnim"];
        
        strokeAnim.keyPath = @"strokeStart"; // re-use the previous animation, as the values are the same (in the next iteration).
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
    _borderStrokeWidth = borderWidth*2.0;
    
    CGFloat halfBorderWidth = borderWidth*0.5; // we're gonna use this a bunch, so might as well pre-calculate
    
    // set the new border layer path
    borderLayerPath = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius, radius} radius:radius-borderWidth startAngle:-M_PI*0.5 endAngle:M_PI*1.5 clockwise:YES];
    
    for (CAShapeLayer* s in borderLayers) { // apply the new border layer path
        s.path = borderLayerPath.CGPath;
        s.lineWidth = _borderStrokeWidth;
    }
    
    // update avatar masking
    CAShapeLayer* s = [CAShapeLayer layer];
    avatarImageLayer.frame = CGRectMake(halfBorderWidth, halfBorderWidth, self.frame.size.width-borderWidth, self.frame.size.height-borderWidth); // update avatar image frame
    s.path = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius-halfBorderWidth, radius-halfBorderWidth} radius:radius-borderWidth startAngle:0 endAngle:M_PI*2.0 clockwise:YES].CGPath;
    avatarImageLayer.mask = s;
}

-(void) setBorderStrokeWidth:(CGFloat)borderStrokeWidth {
    _borderStrokeWidth = borderStrokeWidth;
    for (CAShapeLayer* s in borderLayers) s.lineWidth = _borderStrokeWidth;
}

-(void) setBorderColors:(NSArray *)borderColors {
    _borderColors = borderColors;
    
    // update colors
    for (int i = 0; i < borderLayers.count; i++) ((CAShapeLayer*)borderLayers[i]).strokeColor = ((UIColor*)borderColors[i]).CGColor;
}

-(void) setBorderValues:(NSArray *)borderValues {
    _borderValues = borderValues;
    [self populateBorderLayers];
    [self updateBorderStrokeValues];
}

-(void) calculateCumulativeValues {
    NSMutableArray* cumulativeValues = [NSMutableArray arrayWithObject:@(0.0)];
    
    CGFloat cumulativeValue = 0;
    for (NSNumber* n in _borderValues) {
        cumulativeValue += [n floatValue];
        [cumulativeValues addObject:[NSNumber numberWithFloat:cumulativeValue]];
    }
    cumulativeBorderValues = [cumulativeValues copy];
    
}

@end
