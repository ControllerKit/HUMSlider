//
//  HUMSlider.m
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import "HUMSlider.h"

// Animation Durations
static NSTimeInterval const HUMTickAlphaDuration = 0.20;
static NSTimeInterval const HUMTickMovementDuration = 0.5;
static NSTimeInterval const HUMSecondTickDuration = 0.35;
static NSTimeInterval const HUMTickAnimationDelay = 0.025;

// Positions
static CGFloat const HUMTickOutToInDifferential = 8;
static CGFloat const HUMImagePadding = 8;

// Sizes
static CGFloat const HUMTickHeight = 6;
static CGFloat const HUMTickWidth = 1;

@interface HUMSlider ()
@property (nonatomic) NSArray *tickViews;
@property (nonatomic) NSArray *allTickBottomConstraints;

@property (nonatomic) NSArray *spacerViews;
@property (nonatomic) NSArray *allSpacerBottomConstraints;

@property (nonatomic) UIImage *leftTemplate;
@property (nonatomic) UIImage *rightTemplate;

@property (nonatomic) UIImageView *leftSaturatedImageView;
@property (nonatomic) UIColor *leftSaturatedColor;
@property (nonatomic) UIImageView *leftDesaturatedImageView;
@property (nonatomic) UIColor *leftDesaturatedColor;
@property (nonatomic) UIImageView *rightSaturatedImageView;
@property (nonatomic) UIColor *rightSaturatedColor;
@property (nonatomic) UIImageView *rightDesaturatedImageView;
@property (nonatomic) UIColor *rightDesaturatedColor;

@end

@implementation HUMSlider

#pragma mark - Init

- (void)commonInit
{
    // Set default values.
    self.sectionCount = 9;
    self.tickAlphaAnimationDuration = HUMTickAlphaDuration;
    self.tickMovementAnimationDuration = HUMTickMovementDuration;
    self.secondTickMovementAndimationDuration = HUMSecondTickDuration;
    self.nextTickAnimationDelay = HUMTickAnimationDelay;
    
    //These will set the side colors.
    self.saturatedColor = [UIColor redColor];
    self.desaturatedColor = [UIColor lightGrayColor];
    
    self.tickColor = [UIColor darkGrayColor];
    
    // Add self as target.
    [self addTarget:self
             action:@selector(sliderAdjusted)
   forControlEvents:UIControlEventValueChanged];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    //[self animateAllTicksIn:YES];
    [self setNeedsUpdateConstraints];
    [self updateConstraints];
    [self layoutIfNeeded];
    
}

#pragma mark - Ticks

- (void)nukeOldTicks
{
    for (UIView *tick in self.tickViews) {
        [tick removeFromSuperview];
    }
    
    self.tickViews = nil;
    
    for (UIView *spacer in self.spacerViews) {
        [spacer removeFromSuperview];
    }

    self.spacerViews = nil;

    [self layoutIfNeeded];
}

- (void)setupTicks
{
    NSMutableArray *tickBuilder = [NSMutableArray array];
    for (NSInteger i = 0; i < self.sectionCount; i++) {
        UIView *tick = [[UIView alloc] init];
        tick.backgroundColor = self.tickColor;
        tick.alpha = 0;
        tick.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:tick];
        [self sendSubviewToBack:tick];
        [tickBuilder addObject:tick];
    }
    
    self.tickViews = tickBuilder;
    
    NSMutableArray *spacerBuilder = [NSMutableArray array];
    for (NSInteger i = 0; i <= self.sectionCount; i++) {
        UIView *spacer = [[UIView alloc] init];
        spacer.backgroundColor = [UIColor clearColor];
        spacer.alpha = 1;
        spacer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:spacer];
        [self sendSubviewToBack:spacer];
        [spacerBuilder addObject:spacer];
    }

    self.spacerViews = spacerBuilder;
    
    [self setupTicksAutolayout];
}

#pragma mark Autolayout

- (void)setupTicksAutolayout
{
    
    NSMutableArray *bottoms = [NSMutableArray array];
    
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:[self trackRectForBounds:self.bounds]
                                          value:self.value];
    CGFloat thumbWidth = CGRectGetWidth(thumbRect);
    
    CGFloat leftImageSize = self.leftDesaturatedImageView.image.size.width + HUMTickOutToInDifferential + (thumbWidth / 2.25);
    CGFloat rightImageSize = self.rightDesaturatedImageView.image.size.width + HUMTickOutToInDifferential + (thumbWidth / 2.25);
    
    for (NSInteger i = 0; i <= self.sectionCount; i++) {
        
        UIView *spacer = self.spacerViews[i];
        
        if (i < [self.tickViews count]) {
            UIView *tick = self.tickViews[i];
            [self pinTickWidthAndHeight:tick];
            [bottoms addObject:[self pinBottom:tick]];
            
            // Pin the spacer tick to the tick
            [self addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:tick
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1
                                                              constant:0]];
        }
        
        // Pin height of spacer
        [self addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:0
                                                        multiplier:1
                                                          constant:HUMTickHeight]];
        [self pinBottom:spacer];
        
        if (i == 0) {
            [spacer addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:0
                                                              multiplier:1
                                                                constant:leftImageSize]];
        } else if (i == self.sectionCount) {
            [spacer addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:0
                                                              multiplier:1
                                                                constant:rightImageSize]];
        } else if (i < (self.sectionCount - 1)) {
            // make all the spacers equal width
            [self addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.spacerViews[i+1]
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0]];
        }
        
        if (i > 0 && i < self.sectionCount) {
            // Pin the spacer to the previous tick
            [self addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.tickViews[i-1]
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1
                                                              constant:0]];
        }
        
    }
    
    // ad on the last spacer
    
    
    UIView *spacer = [self.spacerViews lastObject];
    // Pin height of spacer
    [self addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:0
                                                    multiplier:1
                                                      constant:HUMTickHeight]];
    [self pinBottom:spacer];
    
    // Pin the spacer to the previous tick
    [self addConstraint:[NSLayoutConstraint constraintWithItem:spacer
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:[self.tickViews lastObject]
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:0]];
    
    // pin the first and last spacers to the superviews.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:[self.spacerViews firstObject]
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:[[self.spacerViews firstObject] superview]
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:0]]; // TODO actual track position
    [self addConstraint:[NSLayoutConstraint constraintWithItem:[self.spacerViews lastObject]
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:[[self.spacerViews lastObject] superview]
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:0]]; // TODO actual track position
    
    // end
    
    self.allTickBottomConstraints = bottoms;
    [self layoutIfNeeded];
}

- (void)pinTickWidthAndHeight:(UIView *)currentTick
{
    // Pin width of tick
    [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:0
                                                    multiplier:1
                                                      constant:HUMTickWidth]];
    // Pin height of tick
    [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:0
                                                    multiplier:1
                                                      constant:HUMTickHeight]];
}

- (NSLayoutConstraint *)pinBottom:(UIView *)currentTick
{
    // Pin bottom of tick to top of track.
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:currentTick
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:[self tickOutPosition]];
    [self addConstraint:bottom];
    return bottom;
}

#pragma mark - Images

- (void)setupSaturatedAndDesaturatedImageViews
{
    // Left
    self.leftDesaturatedImageView = [[UIImageView alloc] init];
    self.leftDesaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.leftDesaturatedImageView];
    
    self.leftSaturatedImageView = [[UIImageView alloc] init];
    self.leftSaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftSaturatedImageView.alpha = 0.0f;
    [self addSubview:self.leftSaturatedImageView];
    
    // Right
    self.rightDesaturatedImageView = [[UIImageView alloc] init];
    self.rightDesaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.rightDesaturatedImageView];
    
    self.rightSaturatedImageView = [[UIImageView alloc] init];
    self.rightSaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightSaturatedImageView.alpha = 0;
    [self addSubview:self.rightSaturatedImageView];
    
    // Pin desaturated image views.
    [self pinView:self.leftDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeLeft];
    [self pinView:self.leftDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeCenterY constant:HUMTickOutToInDifferential];
    [self pinView:self.rightDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeRight];
    [self pinView:self.rightDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeCenterY constant:HUMTickOutToInDifferential];
    
    // Pin saturated image views to desaturated image views.
    [self pinView1Center:self.leftSaturatedImageView toView2Center:self.leftDesaturatedImageView];
    [self pinView1Center:self.rightSaturatedImageView toView2Center:self.rightDesaturatedImageView];
    
    // Reset colors
    self.saturatedColor = self.saturatedColor;
    self.desaturatedColor = self.desaturatedColor;
}

- (void)sliderAdjusted
{
    CGFloat halfValue = (self.minimumValue + self.maximumValue) / 2.0f;
    
    if (self.value > halfValue) {
        self.rightSaturatedImageView.alpha = (self.value - halfValue) / halfValue;
        self.leftSaturatedImageView.alpha = 0;
    } else {
        self.leftSaturatedImageView.alpha = (halfValue - self.value) / halfValue;
        self.rightSaturatedImageView.alpha = 0;
    }
}

- (UIImage *)transparentImageOfSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - Superclass Overrides

- (CGSize)intrinsicContentSize
{
    CGFloat maxPoppedHeight = CGRectGetHeight([self thumbRectForBounds:self.bounds trackRect:[self trackRectForBounds:self.bounds] value:self.value]) + HUMTickHeight;
    
    CGFloat largestHeight = MAX(CGRectGetMaxY(self.rightSaturatedImageView.frame),
                                MAX(CGRectGetMaxY(self.leftSaturatedImageView.frame), maxPoppedHeight));
    return CGSizeMake(CGRectGetWidth(self.frame), largestHeight);
}

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds
{
    return self.leftDesaturatedImageView.frame;
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds
{
    return self.rightDesaturatedImageView.frame;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect superRect = [super trackRectForBounds:bounds];
    superRect.origin.y += HUMTickHeight;
    
    // Adjust the track rect so images are always a consistent padding.
    
    if (self.leftDesaturatedImageView) {
        CGFloat leftImageViewToTrackOrigin = CGRectGetMinX(superRect) - CGRectGetMaxX(self.leftDesaturatedImageView.frame);
        
        if (leftImageViewToTrackOrigin != HUMImagePadding) {
            CGFloat leftAdjust = leftImageViewToTrackOrigin - HUMImagePadding;
            superRect.origin.x -= leftAdjust;
            superRect.size.width += leftAdjust;
        }
    }
    
    if (self.rightDesaturatedImageView) {
        CGFloat endOfTrack = CGRectGetMaxX(superRect);
        CGFloat startOfRight = CGRectGetMinX(self.rightDesaturatedImageView.frame);
        CGFloat trackEndToRightImageView = startOfRight - endOfTrack;
        
        if (trackEndToRightImageView != HUMImagePadding) {
            CGFloat rightAdjust = trackEndToRightImageView - HUMImagePadding;
            superRect.size.width += rightAdjust;
        }
    }
    
    return superRect;
}

#pragma mark - Convenience

- (void)pinView:(UIView *)view toSuperViewAttribute:(NSLayoutAttribute)attribute
{
    [self pinView:view toSuperViewAttribute:attribute constant:0];
}

- (void)pinView:(UIView *)view toSuperViewAttribute:(NSLayoutAttribute)attribute constant:(CGFloat)constant
{
    [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                               attribute:attribute
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:view.superview
                                                               attribute:attribute
                                                              multiplier:1
                                                                constant:constant]];
}

- (void)pinView1Center:(UIView *)view1 toView2Center:(UIView *)view2
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view1
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view2
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view1
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view2
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    
}

#pragma mark - General layout

//- (void)layoutSubviews
//{
//    [super layoutSubviews];
//}

#pragma mark - Overridden Setters

- (void)setValue:(float)value
{
    [super setValue:value];
    [self sliderAdjusted];
}

- (void)setSectionCount:(NSUInteger)sectionCount
{
//    // Warn the developer that they need to use an odd number of sections.
//    NSAssert(sectionCount % 2 != 0, @"Must use an odd number of sections!");
    
    _sectionCount = sectionCount;
    
    [self nukeOldTicks];
    [self setupTicks];
}

- (void)setMinimumValueImage:(UIImage *)minimumValueImage
{
    if (!self.leftDesaturatedImageView) {
        [self setupSaturatedAndDesaturatedImageViews];
    }
    
    [super setMinimumValueImage:[self transparentImageOfSize:minimumValueImage.size]];
    self.leftTemplate = [minimumValueImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.leftSaturatedImageView.image = self.leftTemplate;
    self.leftDesaturatedImageView.image = self.leftTemplate;
    
    // Bring to the front or they'll get covered by the minimum value image.
    [self bringSubviewToFront:self.leftDesaturatedImageView];
    [self bringSubviewToFront:self.leftSaturatedImageView];
}

- (void)setMaximumValueImage:(UIImage *)maximumValueImage
{
    if (!self.leftDesaturatedImageView) {
        [self setupSaturatedAndDesaturatedImageViews];
    }
    
    [super setMaximumValueImage:[self transparentImageOfSize:maximumValueImage.size]];
    self.rightTemplate = [maximumValueImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.rightSaturatedImageView.image = self.rightTemplate;
    self.rightDesaturatedImageView.image = self.rightTemplate;
    
    // Bring to the front or they'll get covered by the minimum value image.
    [self bringSubviewToFront:self.rightDesaturatedImageView];
    [self bringSubviewToFront:self.rightSaturatedImageView];
}

- (void)setSaturatedColor:(UIColor *)saturatedColor
{
    _saturatedColor = saturatedColor;
    [self setSaturatedColor:saturatedColor forSide:HUMSliderSideLeft];
    [self setSaturatedColor:saturatedColor forSide:HUMSliderSideRight];
}

- (void)setDesaturatedColor:(UIColor *)desaturatedColor
{
    _desaturatedColor = desaturatedColor;
    [self setDesaturatedColor:desaturatedColor forSide:HUMSliderSideLeft];
    [self setDesaturatedColor:desaturatedColor forSide:HUMSliderSideRight];
}

#pragma mark - Setters for colors on different sides. 

- (void)setSaturatedColor:(UIColor *)saturatedColor forSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            self.leftSaturatedColor = saturatedColor;
            break;
        case HUMSliderSideRight:
            self.rightSaturatedColor = saturatedColor;
            break;
    }
    
    [self imageViewForSide:side saturated:YES].tintColor = saturatedColor;
}

- (UIColor *)saturatedColorForSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            return self.leftSaturatedColor;
            break;
        case HUMSliderSideRight:
            return self.rightSaturatedColor;
            break;
    }
}

- (void)setDesaturatedColor:(UIColor *)desaturatedColor forSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            self.leftDesaturatedColor = desaturatedColor;
            break;
        case HUMSliderSideRight:
            self.rightDesaturatedColor = desaturatedColor;
            break;
    }

    [self imageViewForSide:side saturated:NO].tintColor = desaturatedColor;
}

- (UIColor *)desaturatedColorForSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            return self.leftDesaturatedColor;
            break;
        case HUMSliderSideRight:
            return self.rightDesaturatedColor;
            break;
    }
}

- (UIImageView *)imageViewForSide:(HUMSliderSide)side saturated:(BOOL)saturated
{
    switch (side) {
        case HUMSliderSideLeft:
            if (saturated) {
                return self.leftSaturatedImageView;
            } else {
                return self.leftDesaturatedImageView;
            }
            break;
        case HUMSliderSideRight:
            if (saturated) {
                return self.rightSaturatedImageView;
            } else {
                return self.rightDesaturatedImageView;
            }
            break;
    }
}

- (void)setTickColor:(UIColor *)tickColor
{
    _tickColor = tickColor;
    if (self.tickViews) {
        for (UIView *tick in self.tickViews) {
            tick.backgroundColor = _tickColor;
        }
    }
}

#pragma mark - UIControl touch event tracking
#pragma mark Animate In

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Update the width
    [self animateAllTicksIn:YES];
    [self popTickIfNeededFromTouch:touch];
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)animateTickIfNeededAtIndex:(NSInteger)tickIndex forTouchX:(CGFloat)touchX
{
    UIView *tick = self.tickViews[tickIndex];
    CGFloat startSegmentX = (tickIndex * self.segmentWidth) + self.trackXOrigin;
    CGFloat endSegmentX = startSegmentX + self.segmentWidth;
    
    CGFloat desiredOrigin;
    if (startSegmentX <= touchX && endSegmentX > touchX) {
        // Pop up.
        desiredOrigin = [self tickPoppedPosition];
    } else {
        // Bring down.
        desiredOrigin = [self tickInNotPoppedPositon];
    }
    
    if (CGRectGetMinY(tick.frame) != desiredOrigin) {
        [self animateTickAtIndex:tickIndex
                       toYOrigin:desiredOrigin
                    withDuration:self.tickMovementAnimationDuration
                           delay:0];
    } // else tick is already where it needs to be.
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self popTickIfNeededFromTouch:touch];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)popTickIfNeededFromTouch:(UITouch *)touch
{
    // Figure out where the hell the thumb is.
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];
    CGFloat sliderLoc = CGRectGetMidX(thumbRect);
    
    // Animate tick based on the thumb location
    for (NSInteger i = 0; i < self.tickViews.count; i++) {
        [self animateTickIfNeededAtIndex:i forTouchX:sliderLoc];
    }
}

#pragma mark Animate Out

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [self returnPosition];
    
    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self returnPosition];
    
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self returnPosition];
    
    [super touchesEnded:touches withEvent:event];
}

- (void)returnPosition
{
    [self animateAllTicksIn:NO];
}

#pragma mark - Tick Animation

- (void)animateAllTicksIn:(BOOL)inPosition
{
    CGFloat origin;
    CGFloat alpha;
    
    if (inPosition) { // Ticks are out, coming in
        alpha = 1;
        origin = [self tickInNotPoppedPositon];
    } else { // Ticks are in, coming out.
        alpha = 0;
        origin = [self tickOutPosition];
    }
    
    [UIView animateWithDuration:self.tickAlphaAnimationDuration
                     animations:^{
                         for (UIView *tick in self.tickViews) {
                             tick.alpha = alpha;
                         }
                     } completion:nil];
    
    for (NSInteger i = 0; i < self.sectionCount; i++) {
            [self animateTickAtIndex:i
                           toYOrigin:origin
                        withDuration:self.tickMovementAnimationDuration
                               delay:0];
    }
}

- (void)animateTickAtIndex:(NSInteger)index
                 toYOrigin:(CGFloat)yOrigin
              withDuration:(NSTimeInterval)duration
                     delay:(NSTimeInterval)delay
{
    
    
    NSLayoutConstraint *constraint = self.allTickBottomConstraints[index];
    constraint.constant = yOrigin;
    
    
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:0.6f
          initialSpringVelocity:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:nil];
}

#pragma mark - Calculation helpers

- (CGFloat)trackXOrigin
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return CGRectGetMinX(trackRect);
}

- (CGFloat)trackYOrigin
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return CGRectGetMinY(trackRect);
}

- (CGFloat)segmentWidth
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return floorf(CGRectGetWidth(trackRect) / self.sectionCount);
}

- (CGFloat)thumbHeight
{
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:[self trackRectForBounds:self.bounds]
                                          value:self.value];
    return CGRectGetHeight(thumbRect);
}

- (CGFloat)tickInToPoppedDifferential
{
    CGFloat halfThumb = [self thumbHeight] / 2.0f;
    CGFloat inToUp = halfThumb - HUMTickOutToInDifferential;
    
    return inToUp;
}

- (CGFloat)tickOutPosition
{
    return -(CGRectGetMaxY(self.bounds) - [self trackYOrigin]);
}

- (CGFloat)tickInNotPoppedPositon
{
    return [self tickOutPosition] - HUMTickOutToInDifferential + HUMTickHeight / 2;
}

- (CGFloat)tickPoppedPosition
{
    return [self tickInNotPoppedPositon] - [self tickInToPoppedDifferential] + self.pointAdjustmentForCustomThumb;
}

@end
