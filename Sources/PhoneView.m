#import <UIKit/UIKit.h>
#import "PhoneView.h"

@implementation PhoneView {
    UIView *homeButton;
    UIView *sleepButton;
}

- (instancetype)init {
    return [self initWithScreenSize:CGSizeMake(320, 568)];
}

- (instancetype)initWithScreenSize:(CGSize)screenSize {
    CGRect outerFrame = CGRectInset((CGRect){.size = screenSize}, -20, -20);
    outerFrame.size.height += 140;

    self = [self initWithFrame:outerFrame];
    self.transform = CGAffineTransformMakeScale(0.3, 0.3);

    CALayer *border = [CALayer layer];
    border.frame = self.bounds;
    border.cornerRadius = self.layer.cornerRadius = 40;
    border.borderColor = [UIColor whiteColor].CGColor;
    border.borderWidth = 2.0;
    [self.layer addSublayer:border];

    const float M = 60;
    homeButton = [[UIView alloc] initWithFrame:(CGRect){.size={M,M}}];
    homeButton.layer.borderColor = [UIColor whiteColor].CGColor;
    homeButton.layer.borderWidth = 1.5;
    homeButton.layer.cornerRadius = M/2;
    homeButton.center = CGPointMake(outerFrame.size.width / 2, outerFrame.size.height - M/2 - 20);
    [self addSubview:homeButton];
    
    sleepButton = [[UIButton alloc] initWithFrame:CGRectMake(outerFrame.size.width - 113, -2, 55, 3)];
    self.clipsToBounds = NO;
    self.backgroundColor = [UIColor clearColor];
    sleepButton.backgroundColor = [UIColor whiteColor];
    sleepButton.layer.cornerRadius = 1;
    [self addSubview:sleepButton];
    
    if (screenSize.width > 320) {
        sleepButton.transform = CGAffineTransformMakeRotation(M_PI_2);
        BOOL const is6Plus = screenSize.height == 736;
        CGFloat const y = is6Plus ? 187 : 167;
        
        sleepButton.center = CGPointMake(outerFrame.size.width + 2, y);
        if (is6Plus)
            sleepButton.bounds = CGRectMake(0, 0, 65, 3);
    }

    return self;
}

@end
