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

        if (borderLayerCount != 0) { // set pre-animation border stroke positions.
            
            CAShapeLayer* previousLayer = borderLayers[borderLayerCount-1];
            borderLayer.strokeStart = previousLayer.strokeEnd;
            borderLayer.strokeEnd = previousLayer.strokeEnd;
            
        } else borderLayer.strokeEnd = 0.0; // default value for first layer.
        
        [self.layer insertSublayer:borderLayer atIndex:0];
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
    
    CABasicAnimation* strokeAnim = [CABasicAnimation animation];
    strokeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    strokeAnim.duration = duration;
    
    CGFloat cumulativeValue = 0;
    for (int i = 0; i < borderValues.count; i++) {
        
        cumulativeValue += [borderValues[i] floatValue];
        
        CAShapeLayer* s = borderLayers[i];

        // define stroke animation.
        strokeAnim.keyPath = @"strokeEnd";
        strokeAnim.fromValue = @(s.strokeEnd);
        strokeAnim.toValue = @(cumulativeValue);
        [s addAnimation:strokeAnim forKey:@"endStrokeAnim"];
        
        if ((i+1) < borderValues.count) { // apply animation to next layer's stroke start (values remain the same)
            CAShapeLayer* nextShapeLayer = borderLayers[i+1];
            strokeAnim.keyPath = @"strokeStart"; // re-use the previous animation, as the values are the same.
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
    avatarImageLayer.frame = CGRectMake(halfBorderWidth, halfBorderWidth, self.frame.size.width-borderWidth, self.frame.size.height-borderWidth); // update avatar image frame
    s.path = [UIBezierPath bezierPathWithArcCenter:(CGPoint){radius-halfBorderWidth, radius-halfBorderWidth} radius:radius-borderWidth startAngle:0 endAngle:M_PI*2.0 clockwise:YES].CGPath;
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
