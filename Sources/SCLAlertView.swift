//
//  SCLAlertView.swift
//  SCLAlertView Example
//
//  Created by Viktor Radchenko on 6/5/14.
//  Copyright (c) 2014 Viktor Radchenko. All rights reserved.
//

import UIKit
import UIImage_ImageWithColor

let kCircleHeightBackground: CGFloat = 62.0

// The Main Class
public class SCLAlertView: UIVisualEffectView {
    let kCircleTopPosition: CGFloat = -12.0
    let kCircleBackgroundTopPosition: CGFloat = -15.0
    let kCircleHeight: CGFloat = 56.0
    let kCircleIconHeight: CGFloat = 20.0
    let kTitleTop:CGFloat = 24.0
    let kTitleHeight:CGFloat = 40.0
    let kWindowWidth: CGFloat = 240.0
    let kWindowHeight: CGFloat = 178.0 + 45.0
    let kTextHeight: CGFloat = 90.0

    // UI Colour
    private var viewColor: UIColor { return UIColor.hotPink() }

    // Members declaration
    let baseView = UIView()
    let labelTitle = UILabel()
    let imageView = UIImageView(image: UIImage(named: "Lips"))
    let innerView = UIView()
    let button = UIButton()

    convenience init() {
        self.init(effect: UIBlurEffect(style: .Dark))

        frame = UIScreen.mainScreen().bounds
        autoresizingMask = UIViewAutoresizing.FlexibleHeight | .FlexibleWidth

        baseView.frame = bounds
        baseView.addSubview(innerView)

        innerView.backgroundColor = UIColor(white:1, alpha:1)
        innerView.layer.cornerRadius = 5
        innerView.layer.masksToBounds = true
        innerView.layer.borderWidth = 0.5
        innerView.backgroundColor = UIColor.whiteColor()
        innerView.layer.borderColor = UIColor(hex: 0xCCCCCC).CGColor

        labelTitle.textAlignment = .Center
        labelTitle.font = UIFont(name: "HelveticaNeue-Light", size: 24)
        labelTitle.frame = CGRect(x:12, y:kTitleTop, width: kWindowWidth - 24, height:kTitleHeight)
        labelTitle.textColor = UIColor(hex: 0x4D4D4D)

        imageView.contentMode = .ScaleAspectFit

        button.layer.masksToBounds = true
        button.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        button.addTarget(self, action: "ondone", forControlEvents: .TouchUpInside)
        button.setBackgroundImage(UIImage(color: viewColor), forState: .Normal)

        addSubview(baseView)
        innerView.addSubview(labelTitle)
        innerView.addSubview(imageView)
        innerView.addSubview(button)
    }

    public override func layoutSubviews() {
        frame = UIScreen.mainScreen().bounds
        let sz = frame.size
        var x = (sz.width - kWindowWidth) / 2
        var y = (sz.height - kWindowHeight -  (kCircleHeight / 8)) / 2

        innerView.frame = CGRect(x:x, y:y, width:kWindowWidth, height:kWindowHeight)
        y -= kCircleHeightBackground * 0.6
        x = (sz.width - kCircleHeightBackground) / 2

        y = kTitleTop + kTitleHeight
        imageView.frame = CGRect(x:12, y:y, width: kWindowWidth - 24, height:kTextHeight)

        y += kTextHeight + 14.0

        button.frame = CGRect(x:12, y:y, width:kWindowWidth - 24, height:35)
        button.layer.cornerRadius = 3
    }

    public func showTitle(title: String, completeText: String) {
        alpha = 0

        let rv = UIApplication.sharedApplication().keyWindow?.subviews.first as! UIView
        rv.addSubview(self)
        frame = rv.bounds
        baseView.frame = rv.bounds
        labelTitle.text = title
        button.setTitle(completeText, forState: .Normal)

        self.baseView.frame.origin.y = -400
        UIView.animateWithDuration(0.2, animations: {
            self.baseView.center.y = rv.center.y + 15
            self.alpha = 1
        }, completion: { finished in
            UIView.animateWithDuration(0.2, animations: {
                self.baseView.center = rv.center
            })
        })
    }

    @objc func ondone() {
        UIView.animateWithDuration(0.2, animations: {
            self.alpha = 0
        }, completion: { finished in
            self.removeFromSuperview()
        })
    }
}
