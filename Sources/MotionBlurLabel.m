#import "MotionBlurLabel.h"
#import "MotionBlurFilter.h"
@import UIKit;


@implementation MotionBlurLabel {
    UIView *blur;
    UILabel *label;
    BOOL shouldBlur;
}
@dynamic isBlurred, text;

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    self.opaque = YES;
    label = [UILabel new];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = 4;
    id attrs = @{NSParagraphStyleAttributeName:paragraphStyle};
    
    label.attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:attrs];
    label.textColor = [UIColor colorWithHue:0.93 saturation:1 brightness:1 alpha:1];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
    label.numberOfLines = 0;
    [self addSubview:label];
    return self;
}

- (void)prepare {
    if (blur)
        return;
    
    UIImage *snap = [self layerSnapshot];
    if (!snap)
        return;
    
    if (blur)   // how on earth is this check necessary?!
        return; // everything is on main thread: I checked
    
    blur = [UIView new];
    blur.alpha = 0.f;
    blur.frame = self.bounds;
    
    __block CGImageRef blurredImgRef;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CIContext *context = [CIContext contextWithOptions:@{ kCIContextPriorityRequestLow : @YES }];
        CIImage *inputImage = [CIImage imageWithCGImage:snap.CGImage];
        
        MotionBlurFilter *motionBlurFilter = [[MotionBlurFilter alloc] init];
        [motionBlurFilter setDefaults];
        motionBlurFilter.inputAngle = @(M_PI);
        motionBlurFilter.inputImage = inputImage;
        motionBlurFilter.inputRadius = @100;
        
        CIImage *outputImage = motionBlurFilter.outputImage;
        blurredImgRef = [context createCGImage:outputImage fromRect:outputImage.extent];

        dispatch_async(dispatch_get_main_queue(), ^{
            blur.layer.contents = (__bridge id)(blurredImgRef);
            CGImageRelease(blurredImgRef);
            blur.alpha = shouldBlur ? 1.f : 0.f;
            [label addSubview:blur];
        });
    });
}

- (UIImage *)layerSnapshot {
    if (CGRectIsEmpty(self.bounds))
        return nil;
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] setFill];
    CGContextFillRect(graphicsContext, self.bounds);
    
    // good explanation of differences between
    // drawViewHierarchyInRect:afterScreenUpdates: and
    // renderInContext: https://github.com/radi/LiveFrost/issues/10#issuecomment-28959525
    
    [label.layer renderInContext:graphicsContext];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (BOOL)isBlurred {
    return shouldBlur ?: blur.alpha > 0;
}

- (void)setIsBlurred:(BOOL)isBlurred {
    blur.alpha = isBlurred ? 1 : 0;
    shouldBlur = isBlurred;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    label.frame = blur.frame = self.bounds;
    [self prepare];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    //    label.backgroundColor = self.window.backgroundColor;
    [self prepare];
}

- (NSString *)text {
    return label.text;
}

@end
