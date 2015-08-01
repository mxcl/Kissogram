@import UIKit.UIView;

@interface MotionBlurLabel : UIView
- (instancetype)initWithText:(NSString *)text;

@property (nonatomic) BOOL isBlurred;
@property (nonatomic, readonly) NSString *text;
@end
